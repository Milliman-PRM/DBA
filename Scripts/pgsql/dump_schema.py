"""
## CODE OWNERS: Ben Wyatt, Michael Reisz

### OBJECTIVE:
  Dump database schemas, roles, and privileges for all PostgreSQL
    databases on a given server

  Updates the IndyIT/DBA repo with the latest documentation if anything changes
    and sends an email notification to the DBA, so that they
    can comment on the commit in github

### DEVELOPER NOTES:
"""
import sys
import os
import subprocess
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

RECIPIENT_LIST = ['ben.wyatt@milliman.com']
USER_EMAIL = 'ben.wyatt@milliman.com'

def send_notification(subject, message):
    """
        Send a notification e-mail
    """

    # Convert the message string
    message = MIMEText(message)

    # Build the e-mail
    msg = MIMEMultipart('alternative')
    msg['Subject'] = 'PRM Notification: ' + subject
    msg['From'] = USER_EMAIL
    msg['To'] = ', '.join(RECIPIENT_LIST)
    msg.attach(message)

    # Send the message via local SMTP server.
    email = smtplib.SMTP('smtp.milliman.com')
    email.sendmail(msg['From'], RECIPIENT_LIST, msg.as_string())
    email.quit()

def build_repo_url(
        base_url,
        auth_token
):
    """ Build a repo URL that includes an auth token for clone/push operations """
    return base_url.replace("://", "://" + auth_token + "@")

def execute_dump(
        pgsql_username,
        target_server,
        repo_url,
        target_file
):
    """ Utilize pg_dumpall to maintain database documentation in a git repo """

    path_to_git = "L:/Hotware/git/PortableGit_2.5.3.windows.1.github.0/cmd/git.exe"
    path_to_pgdumpall = "L:/Hotware/Postgresql/pg_dumpall.exe"

    try:

        # Run pg_dumpall to dump
        subprocess.check_call([path_to_pgdumpall, "-h", target_server, "-p", "5432",
                               "-U", pgsql_username, "-w",
                               "-f", target_file, "--no-tablespaces",
                               "--schema-only"])

        # Change to the repo directory to issue git commands
        #os.chdir(os.path.relpath("DBA"))

        # Check for changes
        process_output = subprocess.check_output([path_to_git, "status", "--porcelain"])
        print(process_output)

        # Commit and push back to master if any changes are found
        if len(process_output.strip()) > 0:
            commit_message = "Updated schema documentation for " + target_server
            subprocess.check_call([path_to_git, "add", "*"])
            subprocess.check_call([path_to_git, "commit", "-am", str(commit_message)])
            subprocess.check_call([path_to_git, "push", repo_url, "HEAD:master",
                                   "--verbose", "--force"])
            send_notification(commit_message, commit_message)
        else:
            print("No changes found")

    except subprocess.CalledProcessError as err:
        send_notification(err, err)
        print(err)
        raise

if __name__ == '__main__':
    # Script args: hostname, github url, path to target file

    assert len(sys.argv) == 4, 'Unexpected number of arguments passed.'

    execute_dump(
        pgsql_username=os.environ['ephi_username'],
        target_server=str(sys.argv[1]),
        repo_url=build_repo_url(str(sys.argv[2]), os.environ['OAUTH_TOKEN']),
        target_file=str(sys.argv[3])
    )
