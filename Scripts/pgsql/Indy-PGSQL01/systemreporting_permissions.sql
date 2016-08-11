/*
    ## CODE OWNERS: Ben Wyatt

    ### OBJECTIVE:
      Assign proper permissions to the systemreporting database and its contents

      Since the message column in qvauditlog contains PHI, that column is restricted
        to access only by the indy_ePHI_SystemReporting group role and its members

    ### DEVELOPER NOTES:
      Run only the portions that are needed. In PGAdmin3 and most other SQL
        clients, you can select a portion of the script and click a run button
        to run just the selected porition.
*/

-- Create ePHI role and add members, if necessary
CREATE ROLE "indy_ePHI_SystemReporting"
  NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;

GRANT "indy_ePHI_SystemReporting" TO "michael.reisz";
GRANT "indy_ePHI_SystemReporting" TO "kelsie.stevenson";
GRANT "indy_ePHI_SystemReporting" TO "afsheen.khan";
GRANT "indy_ePHI_SystemReporting" TO "surjit.malhi";

-- Top-level permissions
GRANT ALL ON DATABASE systemreporting TO "indy_ePHI_SystemReporting";
REVOKE ALL ON DATABASE systemreporting FROM public;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO public;

/*
  Impersonate the indy_ePHI_SystemReporting role and set default permissions

  These permissions will apply to any new tables created by the indy_ePHI_SystemReporting
    or its members, but not to tables created by other roles
*/
set role "indy_ePHI_SystemReporting";
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON TABLES
    TO "indy_ePHI_SystemReporting";
set role "ben.wyatt";

-- Set permissions and correct owners for all tables
ALTER TABLE public."group"
  OWNER TO "indy_ePHI_SystemReporting";
GRANT ALL ON TABLE public."group" TO "indy_ePHI_SystemReporting";
GRANT SELECT ON TABLE public."group" TO public;

ALTER TABLE public.iislog
  OWNER TO "indy_ePHI_SystemReporting";
GRANT ALL ON TABLE public.iislog TO "indy_ePHI_SystemReporting";
GRANT SELECT ON TABLE public.iislog TO public;

ALTER TABLE public.qvsessionlog
  OWNER TO "indy_ePHI_SystemReporting";
GRANT ALL ON TABLE public.qvsessionlog TO "indy_ePHI_SystemReporting";
GRANT SELECT ON TABLE public.qvsessionlog TO public;

ALTER TABLE public.report
  OWNER TO "indy_ePHI_SystemReporting";
GRANT ALL ON TABLE public.report TO "indy_ePHI_SystemReporting";
GRANT SELECT ON TABLE public.report TO public;

ALTER TABLE public.selected_fields
  OWNER TO "indy_ePHI_SystemReporting";
GRANT ALL ON TABLE public.selected_fields TO "indy_ePHI_SystemReporting";
GRANT SELECT ON TABLE public.selected_fields TO public;

ALTER TABLE public."user"
  OWNER TO "indy_ePHI_SystemReporting";
GRANT ALL ON TABLE public."user" TO "indy_ePHI_SystemReporting";
GRANT SELECT ON TABLE public."user" TO public;

-- Note the column-specific permissions for the public role on this TABLE
-- This protects the message column from being accessed by non-privileged users
ALTER TABLE public.qvauditlog
  OWNER TO "indy_ePHI_SystemReporting";
GRANT ALL ON TABLE public.qvauditlog TO "indy_ePHI_SystemReporting";
GRANT SELECT(id) ON public.qvauditlog TO public;
GRANT SELECT(useraccessdatetime) ON public.qvauditlog TO public;
GRANT SELECT(document) ON public.qvauditlog TO public;
GRANT SELECT(eventtype) ON public.qvauditlog TO public;
GRANT SELECT(isreduced) ON public.qvauditlog TO public;
GRANT SELECT(fk_user_id) ON public.qvauditlog TO public;
GRANT SELECT(fk_group_id) ON public.qvauditlog TO public;
GRANT SELECT(fk_report_id) ON public.qvauditlog TO public;
GRANT SELECT(adddate) ON public.qvauditlog TO public;

-- Set permissions and owners for all views
ALTER TABLE public.view_activity_log
  OWNER TO "indy_ePHI_SystemReporting";
GRANT ALL ON TABLE public.view_activity_log TO "indy_ePHI_SystemReporting";
GRANT SELECT ON TABLE public.view_activity_log TO public;

ALTER TABLE public.view_group
  OWNER TO "indy_ePHI_SystemReporting";
GRANT ALL ON TABLE public.view_group TO "indy_ePHI_SystemReporting";
GRANT SELECT ON TABLE public.view_group TO public;

ALTER TABLE public.view_session_log
  OWNER TO "indy_ePHI_SystemReporting";
GRANT ALL ON TABLE public.view_session_log TO "indy_ePHI_SystemReporting";
GRANT SELECT ON TABLE public.view_session_log TO public;

ALTER TABLE public.view_user
  OWNER TO "indy_ePHI_SystemReporting";
GRANT ALL ON TABLE public.view_user TO "indy_ePHI_SystemReporting";
GRANT SELECT ON TABLE public.view_user TO public;
