/*
    ## CODE OWNERS: Ben Wyatt

    ### OBJECTIVE:
		Meta-script to generate DROP statements to be executed against contents of a specified list of schemas in SQL Server.

    ### DEVELOPER NOTES:
      Copy the output column and paste into a new query file to execute.
				It would be possible to modify this script to just execute all of the commands instead of outputting them,
				but I would prefer to have an opportunity to review what it is doing first.
*/

declare @SchemaName varchar(200)
declare @SchemaID int
create table #DropStatements (DropCommand varchar(max))

-- Cursors are disgusting, but this is one case where they're needed.
-- Alter the list of schema names below as needed when the script is being run.
DECLARE schema_cursor CURSOR FOR
	select name, schema_id from sys.schemas
	where name in ('')

OPEN schema_cursor

FETCH NEXT FROM schema_cursor
INTO @SchemaName, @SchemaID

-- Iterate over the cursor contents
WHILE @@FETCH_STATUS = 0
BEGIN

	insert #DropStatements (DropCommand)
	Values ('--'),('-- Drop statements for schema: ' + @SchemaName),('--')

	-- Generate drop statements for views
	insert #DropStatements (DropCommand)
	Values ('-- Views for schema: ' + @SchemaName),('--')
	insert #DropStatements (DropCommand)
	select 'Drop view [' + @SchemaName + '].[' + name + '];' as DropCommand  from sys.views where schema_id = @SchemaID

	-- Generate drop statements for tables
	insert #DropStatements (DropCommand)
	Values ('--'),('-- Tables for schema: ' + @SchemaName),('--')
	insert #DropStatements (DropCommand)
	select 'Drop table [' + @SchemaName + '].[' + name + '];' from sys.tables where schema_id = @SchemaID and type = 'u'

	-- generate drop statement for schema
	insert #DropStatements (DropCommand)
	Values ('--'),('-- Drop schema: ' + @SchemaName),('--')
	insert #DropStatements (DropCommand)
	select 'DROP SCHEMA ' + @SchemaName + ';'

	FETCH NEXT FROM schema_cursor INTO @SchemaName, @SchemaID
END

-- Output the generated commands and clean up the mess
select * from #DropStatements

DEALLOCATE schema_cursor
DROP TABLE #DropStatements
