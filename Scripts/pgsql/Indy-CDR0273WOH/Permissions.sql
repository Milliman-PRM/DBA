reassign owned by indy_jenkins_0273woh to "indy-cdrbot-0273woh";


-- Switch role to bot user to modify permissions
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

--set role "ben.wyatt";

select * from 