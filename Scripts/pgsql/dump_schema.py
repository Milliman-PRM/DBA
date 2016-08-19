"""
## CODE OWNERS: Ben Wyatt

### OBJECTIVE:
  Dump database schemas, roles, and privileges for all PostgreSQL
    databases on a given server

### DEVELOPER NOTES:
"""
import re
import sys
import os
import subprocess
import fileinput

def build_repo_url(
        base_url,
        auth_token
):
    """ Build a repo URL that includes an auth token for clone/push operations """
    return base_url.replace("://", "://" + auth_token + "@")

def execute_dump(
        pgsql_username,
        pgsql_password,
        target_server,
        repo_url,
        target_file
):
    """ Utilize pg_dumpall to maintain database documentation in a git repo """

    path_to_git = "L:/Hotware/git/PortableGit_2.5.3.windows.1.github.0/cmd/git.exe"
    path_to_pgdumpall = "L:/Hotware/Postgresql/pg_dumpall.exe"

    # Clone the DBA repo here
    subprocess.call([path_to_git, "clone", repo_url])

    # Run pg_dumpall to dump
    subprocess.check_call([path_to_pgdumpall, "--host", target_server, "--port", "5432",
                           "--username", pgsql_username, "--password", pgsql_password,
                           "--verbose", "--file", target_file, "--no-tablespaces",
                           "--schema-only"])

    """
    Remove lines from the file if they match this expression

    This allows us to make sure timestamps aren't flagged as
        changes by git

    Expression is as specific as possible to ensure only exact matches get
        stripped out of the file
    """ # pylint: disable=pointless-string-statement
    timestamp_expression = r"^-- ((Started)|(Completed)) on 20[0-9]{2}-", \
    "[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}$"

    for line in fileinput.input(target_file, inplace=True):
        if not re.match(timestamp_expression, line):
            print line,

    # Change to the repo directory to issue git commands
    os.chdir(os.path.relpath("DBA"))

    # Check for changes
    process_output = subprocess.check_output([path_to_git, "status", "--porcelain"])
    print process_output

    # Commit and push back to master if any changes are found
        commit_message = "Updated schema documentation for " + target_server
        subprocess.check_call([path_to_git, "add", "*"])
        subprocess.check_call([path_to_git, "commit", "-am", str(commit_message)])
        subprocess.check_call([path_to_git, "push", "--repo=" + repo_url])
    else:
        print "No changes found"

    # Clean up folder, if necessary

if __name__ == '__main__':
    # Script args: hostname, github url, path to target file

    assert len(sys.argv) == 4, 'Unexpected number of arguments passed.'

    execute_dump(
        pgsql_username=os.environ['pgsql_username'],
        pgsql_password=os.environ['pgsql_password'],
        target_server=str(sys.argv[1]),
        repo_url=build_repo_url(str(sys.argv[2]), os.environ['oauth_token']),
        target_file=str(sys.argv[3])
    )
