-- Create new group role
--CREATE GROUP geocoder_users;

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

--set role geocoder_users;

--select * from geocoding_data."Client Name" LIMIT 1;
--select * from tiger_data.in_zip_state LIMIT 1;

GRANT geocoder_users TO "brandon.patterson";
GRANT geocoder_users TO "jacob.krebs";
GRANT geocoder_users TO indy_jenkins_no_ephi;
GRANT geocoder_users TO "jason.altieri";