<#
    ## CODE OWNERS: Ben Wyatt

    ### OBJECTIVE:
		Execute test database restores from a source server against a target

    ### DEVELOPER NOTES:
    

#> 

<#
.SYNOPSIS

Execute database restore tests
.DESCRIPTION

Test restoring specified databases from a source server to a target server. The target server should be a test server that is used for no other purpose.

You must specify either -includeDatabases, -excludeDatabases or -allDatabases. No assumptions are made about the set of databases that will be restored.
.PARAMETER sourceServer

The source SQL Server's name. For named instances, include the instance name in this parameter (i.e., server\instance)
.PARAMETER targetServer

The server the datbase will be restored to. This server should not be used for any other work. For named instances, include the instance name in this parameter (i.e., server\instance)

.PARAMETER includeDatabases

A list of databases to be restored to the target server. You must supply either this parameter or the excludeDatabases parameter.

If this parameter is specified, only the listed databases will be restored.

.PARAMETER excludeDatabases

If this parameter is specified, all non-system databases will be restored except for those listed in this parameter.

.PARAMETER allDatabases

If this flag parameter is present, all non-system databases will be restored.

.PARAMETER dataFilePath

Specifies the target directory for SQL data files post-restore. The files are deleted after the test is complete.

.PARAMETER logFilePath

Specifies the target directory for SQL data files post-restore. The files are deleted after the test is complete.

.PARAMETER procedurePath

Specifies the path to the .sql file that defines the stored procedure to generate restore commands for the selected datbases.
#>

[CmdletBinding()]
Param(
   [Parameter(Mandatory=$True)]
   [string]$sourceServer,
	
   [Parameter(Mandatory=$True)]
   [string]$targetServer,

   [Parameter(ParameterSetName="set1", Mandatory=$True)]
   [string[]]$includeDatabases,

   [Parameter(ParameterSetName="set2", Mandatory=$True)]
   [string[]]$excludeDatabases,

   [Parameter(ParameterSetName="set3", Mandatory=$True)]
   [switch]$allDatabases,

   [string]$dataFilePath="C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\mssql\DATA",

   [string]$logFilePath="C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\mssql\DATA",

   [string]$procedurePath="scripts\mssql\PRM_GenerateRestoreStatements.sql"
)

<#
    INSTALL THE STORED PROCEDURE ON $SOURCESERVER
#>
# Execute the script at $procedurePath against the source server

sqlcmd -S $sourceServer -i $procedurePath

if ($LASTEXITCODE -ne 0) {
    write-output "An error occurred while installing the stored procedure. Make sure the source server has an Admin database with a CommandLog table and that the current user has permission to create objects in that datbase."
    exit $LASTEXITCODE
}
else
{
    Write-Output "Successfully installed stored procedure on $sourceServer"
}

<#
    BUILD A LIST OF DATABASES TO BE TESTED
#>
# Build a where clause here for a query to pull a list of datbase names from the source server
if ($PSCmdlet.ParameterSetName -eq "set1") #includeDatabases
{
    $lastIndex = $includeDatabases.GetUpperBound(0)
    $dbList = ""

    foreach ($d in $includeDatabases)
     {
        $dbList = $dbList + "'$d'"

        if ($d -ne $includeDatabases[$lastIndex])
        {
            $dbList = $dblist + ', '
        }
     }

    $whereClauseCondition = "AND name in ($dbList)"
}
elseif ($PSCmdlet.ParameterSetName -eq "set2") #excludeDatabases
{
    $lastIndex = $excludeDatabases.GetUpperBound(0)
    $dbList = ""

    foreach ($d in $excludeDatabases)
     {
        $dbList = $dbList + "'$d'"

        if ($d -ne $excludeDatabases[$lastIndex])
        {
            $dbList = $dblist + ', '
        }
     }

    $whereClauseCondition = "AND name not in ($dbList)"
}
else #allDatabases
{
    Write-Output "All user datbases will be included."
    $whereClauseCondition = ""
}

$queryString = "select name from sys.databases where name not in ('master', 'model', 'tempdb', 'msdb') $whereclausecondition"

# Query $sourceServer for a list of databases to be backed up, and store the output in a file

sqlcmd -S $sourceServer -Q "$queryString" -o databases.txt -h -1 -W
if ($LASTEXITCODE -ne 0) {
    write-output "Unable to retrieve a list of databases."
    exit $LASTEXITCODE
}
$databases = get-content databases.txt | where {$_.trim().length -gt 0 -and $_.trim() -notlike "* rows affected)"}
rm databases.txt

write-output ""
Write-Output "List of databases to be restore-tested:"
$databases

<#
    ITERATE OVER DATABASES AND PERFORM TEST RESTORES
#>

write-output ""
write-output "Preparing to perform test restores"
write-output "Data files will be written in $datafilepath"
write-output "Log files will be written in $logFilePath"

foreach ($database in $databases)
{
    write-output ""
    write-output "Generating restore commands for $database from $sourceServer"

    $queryString = "exec PRM_GenerateRestoreStatements '$database', '$dataFilePath', '$logFilePath'"
    sqlcmd -S $sourceServer -d Admin -Q $queryString -o restoreCommands.txt -y 0

    if ($LASTEXITCODE -ne 0) {
        write-output "Unable to retrieve restore commands."
        exit $LASTEXITCODE
    }

    $restoreCommands = get-content restoreCommands.txt | where {$_.trim().length -gt 0 -and $_.trim() -notlike "* rows affected)"}
    rm restoreCommands.txt

    write-output ""
    write-output "Restoring $database on $targetServer"

    foreach ($command in $restoreCommands)
    {
        sqlcmd -S $targetServer -Q $command -e

        if ($LASTEXITCODE -ne 0) 
        {
            write-output "Command failed."
            exit $LASTEXITCODE
        }
    }

    write-output "$database was restored successfully on $targetServer"
}

<#
    SUCCESS
#>
write-output ""
write-output "All restore tests were successful on $targetServer"