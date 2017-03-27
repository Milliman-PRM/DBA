<#
    ## CODE OWNERS: Ben Wyatt, Steve Gredell

    ### OBJECTIVE:
		Execute test MongoDB restores from a source server against a target

    ### DEVELOPER NOTES:
    

#> 

<#
.SYNOPSIS

Execute database restore tests
.DESCRIPTION

Test restoring specified MongoDB databases from a source server to a target server. The target server should be a test server that is used for no other purpose.

You must specify either -includeDatabases with a list of databases. No assumptions are made about the set of databases that will be restored.

As a protective feature, databases that already exist on the target server will not be overwritten. A pre-existing datbase will trigger an error and fail the script.
.PARAMETER sourceServer

The source MongoDB server's name. For named instances, include the instance name in this parameter (i.e., server\instance)
.PARAMETER targetServer

The server the datbase will be restored to. This server should not be used for any other work. For named instances, include the instance name in this parameter (i.e., server\instance)

.PARAMETER includeDatabases

A list of databases to be restored to the target server. You must supply either this parameter or the excludeDatabases parameter.

If this parameter is specified, only the listed databases will be restored.

.EXAMPLE
.\RestoreTest.ps1 -sourceServer indy-cdr0273woh -targetServer indy-dbatest01 -includedatabases bayclinictest

Will restore today's backup of bayclinictest from indy-cdr0273woh to indy-dbatest01.

The database will be dropped after it is tested successfully.

#>

[CmdletBinding()]
Param(
   [Parameter(Mandatory=$True)]
   [string]$sourceServer,
	
   [Parameter(Mandatory=$True)]
   [string]$targetServer,

   [Parameter(Mandatory=$True)]
   [string[]]$includeDatabases

)

# Make sure the required executables exist
$executables = @("c:\mongodb\bin\mongo.exe", "c:\mongodb\bin\mongorestore.exe")
foreach ($file in $executables)
{
    if ((test-path $file) -eq $false)
    {
        write-output "ERROR: $file was not found. Tests cannot be completed on this machine."
        exit 42
    }
}

# Make sure no databases exist on the target server
get-date
write-output "Preparing to restore MongoDB backups from $sourceServer to $targetServer"
write-output "Databases to be restored:"
$includeDatabases | format-table
write-output ""

# Query target server for a list of databases
$command = "c:\mongodb\bin\mongo.exe admin --host $targetServer --eval `"db.adminCommand( { listDatabases: 1 } )`" --quiet"
$databaseJSON = invoke-expression $command
$databases = $databaseJSON | ConvertFrom-Json

# Count databases currently on target server
if ($databases.databases.length -gt 1)
{
    write-output "Existing databases were found on the target server. Exiting to preserve data."
    exit 1
}

# Loop over databases and perform test restores
foreach ($database in $includeDatabases)
{
    # Derive the backup file path and make sure it exists before moving forward
    $datestring = get-date -Format "yyyyMMdd"
    $filepath = "\\indy-backup\prm-mongodb\" + $sourceserver + "\" + $sourceServer + "_" + $datestring + "_" + $database + ".gzip"
    if ((test-path $filepath) -eq $false)
    {
        write-output "ERROR: File does not exist: $filepath"
        write-output "Failed to restore $database"
        exit 2
    }
    get-date 
    write-output "Restoring $database from $filepath"

    # Restore database
    $command = "C:\mongodb\bin\mongorestore.exe --gzip --host $targetServer --db $database --archive=$filepath"
    Invoke-Expression $command

    if ($LASTEXITCODE -ne 0)
    {
        write-output "ERROR: Failed to restore $database on $targetServer."
        write-output "Manually log in to $targetServer and delete any remnants of the database that were left behind."
        exit $LASTEXITCODE
    }

    # Drop database
    write-output "Restore complete. Dropping database..."
    $command = "C:\mongodb\bin\mongo.exe $database --host $targetServer --eval `"db.dropDatabase()`" --quiet"
    Invoke-Expression $command

    if ($LASTEXITCODE -ne 0)
    {
        write-output "ERROR: Failed to drop $database from $targetServer after restoring."
        write-output "Manually log in to $targetServer and drop the database."
        exit $LASTEXITCODE
    }
    write-output "Database $database was successfully restored to $targetServer and dropped."
    write-output ""
}

write-output "All test restores were completed successfully on $targetServer"
