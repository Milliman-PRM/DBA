/*
    ## CODE OWNERS: Ben Wyatt

    ### OBJECTIVE:
      Assign proper permissions to the prm_geocoder_dev database and its contents

    ### DEVELOPER NOTES:
      Run only the portions that are needed. In PGAdmin3 and most other SQL
        clients, you can select a portion of the script and click a run button
        to run just the selected porition.
*/

-- Create new group role
CREATE GROUP geocoder_users;

-- Remove access from public group
REVOKE ALL ON SCHEMA public FROM public;
REVOKE ALL ON SCHEMA geocoding_data FROM public;
REVOKE ALL ON SCHEMA tiger FROM public;
REVOKE ALL ON SCHEMA tiger_data FROM public;
REVOKE ALL ON SCHEMA tiger_staging FROM public;
REVOKE ALL ON SCHEMA topology FROM public;

GRANT CREATE ON SCHEMA geocoding_data TO geocoder_users;
GRANT CREATE ON SCHEMA tiger_data TO geocoder_users;
GRANT CREATE ON SCHEMA tiger_staging TO geocoder_users;

GRANT geocoder_users TO "brandon.patterson";
GRANT geocoder_users TO "jacob.krebs";
GRANT geocoder_users TO indy_jenkins_no_ephi;
GRANT geocoder_users TO "jason.altieri";
