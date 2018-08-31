/*
    AUTHOR: Ben Wyatt (stolen from Stack Overflow)

    DESCRIPTION:
        Deletes all tables in the targeted PostgreSQL database

    DEVELOPER NOTES:
        You may find it necessary to run the script 
            multiple times to get past cascading dependencies.
        This is supposed to be caught by the CASCADE clause, but
            it doesn't always work.
*/

DO $$ DECLARE
        r RECORD;
    BEGIN
        FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = current_schema()) LOOP
            EXECUTE 'DROP TABLE IF EXISTS ' || quote_ident(r.tablename) || ' CASCADE';
        END LOOP;
    END $$;