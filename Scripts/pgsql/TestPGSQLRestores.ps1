<#
    ## CODE OWNERS: Ben Wyatt

    ### OBJECTIVE:
		Execute PostgreSQL test database restores from a source server against a target

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

.PARAMETER targetHotwarePath

The path to the correct Hotware folder to utilize for the target server. 

If this is not specified, the script will attempt to retrieve the path from %path_target_pg_hotware%. If the environment variable is not set or is not a valid path, the script will fail.

.PARAMETER sourceHotwarePath

The path to the correct Hotware folder to utilize for the source server.

If this is not specified, the script will attempt to retrieve the path from %path_source_pg_hotware%. If the environment variable is not set or is not a valid path, the script will fail.

.EXAMPLE

.\TestDatbaseRestores.ps1 -sourceServer indy-ss01\SQLEXPRESS -targetServer indy-dbatest01 -alldatabases

Will restore all backups from indy-pgsql02, onto indy-dbatest01. Each database will be dropped after it is tested successfully.

.EXAMPLE
.\TestDatbaseRestores.ps1 -sourceServer "indy-pgsql02" -targetServer indy-dbatest01 -includeDatabases Admin, CMS, SAS201

Will restore only backups of Admin, CMS, and SAS201 from indy-pgsql02, onto indy-dbatest01. Each database will be dropped after it is tested successfully.

.EXAMPLE
.\TestDatbaseRestores.ps1 -sourceServer indy-sql02 -targetServer indy-dbatest01 -excludeDatbases 0032ODM, SSC_HCG_2014

Will restore all backups from indy-pgsql02, with the exception of 0032ODM and SSC_HCG_2014, onto indy-dbatest01. Each database will be dropped after it is tested successfully.
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

   [string]$targetHotwarePath,

   [string]$sourceHotwarePath
)

# Store username in a variable, in the format that PostgreSQL wants in our environment.
if (test-path env:\ephi_username)
{
    $username = $env:ephi_username.ToLower()
}
else
{
    $username = $env:USERNAME.ToLower()
}

<#
    Determine hotware paths

    Make sure they actually contain psql.exe, pg_dumpall.exe, and pg_restore.exe

#>

# Source Path
if ($sourceHotwarePath -eq $null -and $env:path_source_pg_hotware -ne $null)
{
    $sourceHotwarePath = $env:path_source_pg_hotware
}
elseif ($sourceHotwarePath -eq $null -and $sourceHotwarePath -eq $null)
{
    write-output "Source hotware path could not be set. You must specify it with the argument -sourceHotwarePath or the environmental variable path_source_pg_hotware"
    exit 1
}

$TargetPath
if ($targetHotwarePath -eq $null -and $env:path_target_pg_hotware -ne $null)
{
    $targeteHotwarePath = $env:path_target_pg_hotware
}
elseif ($targetHotwarePath -eq $null -and $targetHotwarePath -eq $null)
{
    write-output "Target hotware path could not be set. You must specify it with the argument -targetHotwarePath or the environmental variable path_target_pg_hotware"
    exit 1
}

<#
    
    Make sure $targetServer really is a test server

    Query to see if it has any databases on it other than postgres. If it does, it may not be a test server and the following scripts shouldn't be run, as they are destructive.

#>

$queryString = "select datname from pg_database where datistemplate=false and datname<>'postgres'"
$command = $targetHotwarePath + "psql.exe --dbname=postgres --username=$username --host=$targetServer --tuples-only --command=`"$queryString`" --echo-errors --output=targetdatabases.txt" 
Invoke-Expression $command

if ($LASTEXITCODE -ne 0)
{
    write-output "Error determining whether $testServer is a valid test server."
    exit $LASTEXITCODE
}

$targetDatabases = get-content targetdatabases.txt
rm targetdatabases.txt

if ($targetDatabases.Length -gt 0)
{
    write-output "Existing databases were found on the target server. In order to protect that data, the script will now terminate."
    exit 1
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

    $whereClauseCondition = "AND datname in ($dbList)"
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

    $whereClauseCondition = "AND datname not in ($dbList)"
}
else #allDatabases
{
    Write-Output "All user datbases will be included."
    $whereClauseCondition = ""
}

$queryString = "select datname from pg_database where datistemplate=false and datname<>'postgres' $whereclausecondition;"
$command = $sourceHotwarePath + "psql.exe --dbname=postgres --username=$username --host=$sourceServer --tuples-only --command=`"$queryString`" --echo-errors --output=databases.txt" 
Invoke-Expression $command

if ($LASTEXITCODE -ne 0)
{
    write-output "Error retrieving database list from $sourceServer."
    exit $LASTEXITCODE
}

$databases = get-content databases.txt | where {$_.trim().length -gt 0} | foreach {$_.trim().tolower()}
rm databases.txt

write-output "Databases to be restored:"
$databases
write-output ""

<# 

    Script out roles to copy to target server

#>

write-output "Preparing to copy roles from $sourceServer to $targetServer"
$command = $sourceHotwarePath + "pg_dumpall.exe --host=$sourceServer --username=$username --roles-only --clean --if-exists --file=create_roles.sql"
Invoke-Expression $command

if ($LASTEXITCODE -ne 0)
{
    write-output "Error scripting roles from $sourceServer."
    exit $LASTEXITCODE
}

$dropCommands = get-content create_roles.sql
$dropcommands = $dropcommands | where {$_ -notlike "*"+$username.toLower()+"*" -and $_ -notlike "*postgres*"}
$dropCommands | set-content create_roles.sql

$command = $targetHotwarePath + "psql.exe --dbname=postgres --username=$username --host=$targetServer --file=create_roles.sql --echo-errors -q  --set=ON_ERROR_STOP"
Invoke-Expression $command

if ($LASTEXITCODE -ne 0)
{
    
    rm create_roles.sql
    write-output "Error creating roles on $targetServer."
    exit $LASTEXITCODE
}

rm create_roles.sql

write-output ""

<#

    Iterate over databases and perform test restores

    If the database already exists on the target server, fail the script

#>

foreach ($database in $databases)
{
    write-output "Preparing to restore $database"

    # Build filepath to backup file
    $datestring = get-date -Format "yyyyMMdd"
    $filepath = "\\indy-syn01\indy-resources\backups-pgsql\" + $sourceServer + "_" + $datestring + "_" + $database + ".bak"

    write-output "Restoring from $filepath"

    # Create empty database to restore into
    $command = $targetHotwarePath + "psql.exe --host=$targetServer --username=$username --dbname=postgres -e -q --command='create database $database;'"
    invoke-expression $command
    
    if ($LASTEXITCODE -ne 0)
    {
        write-output "Error creating $database on $targetServer."
        exit $LASTEXITCODE
    }

    # Attempt restore
    $command = $targetHotwarePath + "pg_restore.exe --host=$targetServer --username=$username -e  --dbname=$database $filepath"
    Invoke-Expression $command

    if ($LASTEXITCODE -ne 0)
    {
        write-output "Error restoring $database on $targetServer."
        write-output "Manually log in to $targetServer and delete any remnants of the database that were left behind."
        exit $LASTEXITCODE
    }

    write-output "Restore completed. Dropping database $database"
    # Drop restored database
    $command = $targetHotwarePath + "psql.exe --host=$targetServer --username=$username --dbname=postgres -q --command='drop database $database;'"
    invoke-expression $command

    if ($LASTEXITCODE -ne 0)
    {
        write-output "Error dropping $database from $targetServer after restoring."
        write-output "Manually log in to $targetServer and delete any remnants of the database that were left behind."
        exit $LASTEXITCODE
    }

    write-output "$database was restored to and dropped successfully from $targetserver."
    write-output ""
}


# Report Success
write-output ""
write-output "All test restores from $sourceServer to $targetServer were successful."