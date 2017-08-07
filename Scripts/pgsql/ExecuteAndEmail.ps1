<#
    ## CODE OWNERS: Ben Wyatt, Steve Gredell

    ### OBJECTIVE:
		Execute PostgreSQL test database restores from a source server against a target

    ### DEVELOPER NOTES:


#>

<#
.SYNOPSIS

Execute database restore tests
.DESCRIPTION


.PARAMETER targetServer

Hostname of the server to execute the query against

.PARAMETER targetDatabase

Name of the database to execute the query against.

.PARAMETER queryName

Used to generate the name of the exported file

.PARAMETER queryPath

Path to the query file to be executed

.PARAMETER recipients

Semicolon-delimited list of email recipients

.PARAMETER sender

Email address the results should be sent from

.EXAMPLE

.\ExecuteAndEmail.ps1 -targetServer indy-pgsql01 -targetDatabase systemreporting -queryName test_query_name -recipients prm.support@milliman.com -queryPath "c:\scripts\test.sql" -sender prm.support@milliman.com

Executes c:\scripts\test.sql against the database systemreporting on the server indy-pgsql01.
Results would be written to test_query_name.csv and emailed to prm.support@milliman.com, from prm.support@milliman.com

#>

[CmdletBinding()]
Param(
   [Parameter(Mandatory=$True)]
   [string]$queryName,

   [Parameter(Mandatory=$True)]
   [string]$targetServer,

   [Parameter(Mandatory=$True)]
   [string]$targetDatabase,

   [Parameter(Mandatory=$True)]
   [string]$recipients,

   [Parameter(Mandatory=$True)]
   [string]$sender,

   [Parameter(Mandatory=$True)]
   [string]$queryPath,

   [Parameter()]
   [string]$hotwarePath
)

# Configure Hotware Path
if ($hotwarePath -eq $null -and $env:path_hotware -ne $null)
{
    $hotwarePath = $env:path_hotware
}
elseif ($hotwarePath -eq $null -and $env:path_hotware -eq $null)
{
    write-output "Hotware path could not be determined. You must specify it with the argument -hotwarePath or the environmental variable path_hotware"
    exit 1
}

$hotwarePath = $hotwarePath + 'Postgresql\v9.6.2\'

# Store username in a variable, in the format that PostgreSQL wants in our environment.
if (test-path env:\ephi_username)
{
    $username = $env:ephi_username.ToLower()
}
else
{
    $username = $env:USERNAME.ToLower()
}

$outputFile = $queryName + ".csv"

$command = $hotwarePath + "psql.exe --dbname=$targetDatabase --username=$username -A -F ',' --host=$targetServer --file=`"$queryPath`"  --echo-errors --output='$outputFile'"
Invoke-Expression $command

if ($LASTEXITCODE -ne 0)
{
    write-output "Error executing query"
    exit $LASTEXITCODE
}

Send-MailMessage -To $recipients -From $sender -Attachments "$outputFile" -Subject $queryName -SmtpServer "smtp.milliman.com"
