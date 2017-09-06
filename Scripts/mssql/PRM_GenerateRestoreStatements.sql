/*
    ## CODE OWNERS: Ben Wyatt, Steve Gredell

    ### OBJECTIVE:
		Generate commands to restore a database from its current backup chain.

    ### DEVELOPER NOTES:
    This is intended for scheduled usage, as a tool to aid with backup restore validation.

    ### PREREQUISITES:
	This script assumes that default logical filenames are used everywhere.
		If this is found to not be true, the script can be adjusted later.

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
	,@data_file_path varchar(400)
	,@log_file_path varchar(400)
)

AS
BEGIN
		DECLARE @LastFullDate datetime
		DECLARE @LastFullID int

		DECLARE @LastDiffDate datetime
		DECLARE @LastDiffID int

		DECLARE @DataFileName varchar(100)
		DECLARE @LogFileName varchar(100)

		DECLARE @ServerName varchar(80)

		SELECT @ServerName = cast(SERVERPROPERTY('ServerName') as varchar(80))

		-- Handle special-case filenames and set defaults otherwise
		IF @ServerName = 'Indy-SQL02'
		BEGIN
			IF @databasename = 'SSISDB'
			BEGIN
				set @DataFileName = 'SSISDB'
				set @LogFileName = 'SSISDB'
			END
			ELSE IF @databasename = 'SSS_HCG_2014'
			BEGIN
				SET @DataFileName = 'SSC_HCG_2014'
				SET @LogFileName = 'SSC_HCG_2014_log'
			END
			ELSE IF @databasename = 'SSC_CORE'
			BEGIN
				SET @DataFileName = 'ICD10_SSC_CORE'
				SET @LogFileName = 'ICD10_SSC_CORE_log'
			END
			ELSE IF @databasename = 'SSC_SOURCE'
			BEGIN
				SET @DataFileName = 'ICD10_SSC_SOURCE'
				SET @LogFileName = 'ICD10_SSC_SOURCE_log'
			END
			ELSE IF @databasename IN ('rgsconfig', 'rgsdyn', 'rtcab', 'rtcshared', 'rtcxds', 'cpsdyn')
			BEGIN
				SET @DataFileName = @databasename + '_data'
				SET @LogFileName = @databasename + '_log'
			END
			ELSE
			BEGIN
				SET @DataFileName = @databasename
				SET @LogFileName = @databasename + '_log'
			END
		END
		ELSE IF @ServerName = 'indy-ss01\sqlexpress' and @databasename = 'NewPortalDB'
		BEGIN
			set @DataFileName = 'dbMyCMS'
			set @LogFileName = 'dbMyCMS_log'
		END
		ELSE
		BEGIN
			SET @DataFileName = @databasename
			SET @LogFileName = @databasename + '_log'
		END


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

		-- Prep commands, with timestamp for ordering
		-- Block overwriting an existing datbase, for safety's sake
		select 'If  exists (select name from master.sys.databases where name = ''' + @databasename + ''') RAISERROR(''Database %s already exists. Exiting to avoid data loss.'', 12, 42, ''' + @databasename + ''');'
				 as Restore_Command,
				 cast('1/1/1900' as datetime) as StartTime -- Sentinel value. Yeah, I know.
		into #BackupCommands

		UNION

		select 'create database [' + @databasename + '];',

				 cast('1/1/1901' as datetime)

		UNION

		-- Get the commands for each relevant backup file
		select
			-- Include file moves for the full backup
			CASE WHEN Backup_Type = 'FULL' THEN
				'RESTORE ' + Restore_Type + ' [' + DatabaseName + '] FROM DISK = ''' + FilePath + ''' WITH MOVE ''' + @DataFileName + ''' TO ''' + @data_file_path + @DataFileName + '.mdf'', MOVE ''' + @LogFileName + ''' TO ''' + @log_file_path + @LogFileName + '.ldf'', REPLACE, NORECOVERY;'
			ELSE
				'RESTORE ' + Restore_Type + ' [' + DatabaseName + '] FROM DISK = ''' + FilePath + ''' WITH NORECOVERY;'
			END as Restore_command, StartTime

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
		select 'RESTORE DATABASE [' + @DatabaseName + '] WITH RECOVERY;', getdate()

		UNION

		-- Add a drop database statement to the end, because we don't want to retain the database
		select top 1 'drop database [' + @databasename + '];'
			, cast('1/1/2100' as datetime) -- Sentinel value. Yeah, I know.


		-- Select out final set of restore commands, properly ordered
		select Restore_command from #BackupCommands order by StartTime

END
GO
