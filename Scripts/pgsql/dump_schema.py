"""
## CODE OWNERS: Ben Wyatt

### OBJECTIVE:
  Dump database schemas, roles, and privileges for all PostgreSQL
    databases on a given server

### DEVELOPER NOTES:
"""
#import re
import sys
import os
import subprocess
#from pathlib import Path

def build_repo_url(
        base_url,
        auth_token
):
    """ Build a repo URL that includes an auth token for clone/push operations """
    full_url = base_url
    full_url = full_url.replace("://", "://" + auth_token + "@")

    return full_url

def execute_dump(
        pgsql_username,
        pgsql_password,
        target_server,
        repo_url,
        target_file
):
    """ Utilize pg_dumpall to maintain database documentation in a git repo """

    print "clone repo here"

    # Clone the DBA repo here
    subprocess.call(["git", "clone", repo_url])

    # Run pg_dumpall to dump
    subprocess.call(["pg_dumpall", "--host", target_server, "--port", "5432",
                     "--username", pgsql_username, "--password", pgsql_password,
                     "--verbose", "--file", target_file, "--no-tablespaces",
                     "--schema-only"])

    # Remove lines from the file

    # Check for changes
    process_output = subprocess.check_output(["git", "status", "--porcelain"])
    print process_output

    # Commit and push back to master if any changes are found
    if len(process_output.strip()) > 1:
        commit_message = "Updated schema documentation for " + target_server
        subprocess.call(["git", "add", "*"])
        subprocess.call(["git", "commit", "-am", str(commit_message)])
        subprocess.call(["git", "push", "--repo=" + repo_url])
    else:
        print "No changes found"

    # Clean up folder, if necessary

if __name__ == '__main__':
    # Script args: hostname, github url, github auth token, path to target file

    assert len(sys.argv) == 4, 'Unexpected number of arguments passed.'

    execute_dump(
        pgsql_username=os.environ['pgsql_username'],
        pgsql_password=os.environ['pgsql_password'],
        target_server=str(sys.argv[1]),
        repo_url=build_repo_url(str(sys.argv[2]), os.environ['oauth_token']),
        target_file=str(sys.argv[3])
    )
