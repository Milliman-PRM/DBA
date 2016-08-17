/*
    ## CODE OWNERS: Ben Wyatt

    ### OBJECTIVE:
      Assign proper permissions to the cdr_woh database and its contents

    ### DEVELOPER NOTES:
      Run only the portions that are needed. In PGAdmin3 and most other SQL
        clients, you can select a portion of the script and click a run button
        to run just the selected porition.
*/

-- Make the bot user the owner of any objects created by the Jenkins login
reassign owned by indy_jenkins_0273woh to "indy-cdrbot-0273woh";

/*

  Set default permissions for tables and sequences in the public schema

  Setting default permissions must be done from the perspective of the role
    which will own the future new objects (or a group role in which the
    owner is a member)

*/

-- Switch role context to bot user to modify permissions
set role "indy-cdrbot-0273woh";

-- Allow ePHI group to select from newly created (future) tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT ON TABLES
    TO "Indy_ePHI_0273WOH";

-- Allow ePHI group to select from existing tables
GRANT SELECT ON ALL TABLES IN SCHEMA public TO "Indy_ePHI_0273WOH";
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO "Indy_ePHI_0273WOH";

-- Allow Jenkins user CRUD rights on future new tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES
    TO indy_jenkins_0273woh;

-- Grant Jenkins user CRUD rights on existing tables
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO indy_jenkins_0273woh;
GRANT SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA public TO indy_jenkins_0273woh;
