/*
    ## CODE OWNERS: Ben Wyatt

    ### OBJECTIVE:
		Configure "full" permissions for a user in a database.
    Can be useful when a user is made owner of a database but objects that existed
      before they were an owner don't allow them permissions.

    ### DEVELOPER NOTES:
		This requires SYSADMIN-level permissions.
*/

-- Grant permission to existing objects
GRANT ALL PRIVILEGES ON SCHEMA public TO "user name"
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO "user name";
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO "user name";
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO "user name";

-- Set default permissions for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO  "user name";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO  "user name";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO  "user name";

-- TEST
SET ROLE "user name";
SELECT public.postgis_version();

-- Set back to YOUR role
SET ROLE "dba role name";
