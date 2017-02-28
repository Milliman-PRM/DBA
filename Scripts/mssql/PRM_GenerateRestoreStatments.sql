/*
    ## CODE OWNERS: Ben Wyatt

    ### OBJECTIVE:
		Generate commands to restore a database from its current backup chain.

    ### DEVELOPER NOTES:
    This is intended for scheduled usage, as a tool to aid with backup restore validation.

    ### PREREQUISITES:
    This script assumes that backups are being done via Ola Hallengren's maintenance scripts,
      with maintenance history written to dbo.CommandLog in a database named Admin.

    Ola's scripts can be found at https://ola.hallengren.com/

*/

USE [Admin]

-- If the procedure already exists, drop it so we can update to the latest version
IF OBJECT_ID('PRM_GenerateRestoreStatements') IS NOT NULL DROP PROCEDURE PRM_GenerateRestoreStatements;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.PRM_GenerateRestoreStatements
(
	-- Add the parameters for the function here
	@databasename varchar(200)
)

AS
BEGIN
		DECLARE @LastFullDate datetime
		DECLARE @LastFullID int

		DECLARE @LastDiffDate datetime
		DECLARE @LastDiffID int

		IF OBJECT_ID('tempdb..#BackupInfo') IS NOT NULL DROP TABLE #BackupInfo
		IF OBJECT_ID('tempdb..#BackupCommands') IS NOT NULL DROP TABLE #BackupCommands

		-- Select recent backups into a temp table
		select id,
			-- Derive file path
			substring(command, charindex('''', command, 0) + 1, charindex('''', command, charindex('''', command, 0) + 1) - charindex('''', command, 0) - 1) as FilePath
			-- Derive backup type
			,case when command like 'BACKUP LOG%' then 'LOG' when command like '%DIFFERENTIAL' then 'DIFFERENTIAL' else 'FULL' end as Backup_Type
			,case when command like 'BACKUP LOG%' then 'LOG' else 'DATABASE' end as Restore_type
			,databasename, command, StartTime, EndTime

		Into #BackupInfo
		from CommandLog
		where CommandType IN ('BACKUP_DATABASE', 'BACKUP_LOG') and DatabaseName = @DatabaseName

		-- If there were no rows returned, the database has never been backed up. This is a problem, so we should throw an error.
		IF @@ROWCOUNT = 0 RAISERROR('Database %s has not been backed up. Schedule a backup for it as soon as possible.', 11, 42, @DatabaseName)

		-- Retrieve info about last full backup
		select top 1 @LastFullDate = StartTime, @LastFullID = ID
		from #BackupInfo
		where Backup_Type = 'FULL'
		order by starttime desc

		-- Retrieve info about last diff backup
		select top 1 @LastDiffDate = StartTime, @LastDiffID = ID
		from #BackupInfo
		where Backup_Type = 'DIFFERENTIAL' AND StartTime > @LastFullDate
		order by starttime desc

		-- Prep commands for restore statements, with timestamp for ordering
		select 'RESTORE ' + Restore_Type + ' ' + DatabaseName + ' FROM DISK = ''' + FilePath + ''' WITH NORECOVERY;' as Restore_command, StartTime
		into #BackupCommands
		from #BackupInfo
		where StartTime >= @LastFullDate -- We don't need to test anything older than the latest full backup
				AND
					(
						ID = @LastFullID
						OR ID = @LastDiffID
						OR (StartTime > @LastDiffDate AND Backup_Type = 'LOG') -- Only pull log backups that have happened since the last diff
					)
		UNION
		-- Include a final statement to initiate recovery (complete backup cycle)
		select 'RESTORE DATABASE ' + @DatabaseName + ' WITH RECOVERY;', getdate()

		-- Select out final set of restore commands, properly ordered
		select Restore_command from #BackupCommands order by StartTime

END
GO
