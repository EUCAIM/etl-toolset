-- Schema upgrade, step 1 of 3: set the live schemas aside
--
-- Run by scripts/reload_database.sh (group "schema") in the same transaction as
-- 2_init_eucaim_cdm_ingestion.sql, 3_init_eucaim_cdm_output.sql, 3z (if present) and
-- 2_schema_reconcile.sql. Never by initdb: Postgres only runs the files at the top level of
-- docker-entrypoint-initdb.d, and this one lives in a subfolder.
--
-- The live schemas are renamed out of the way so that the init files that follow build,
-- under the real names, an empty copy of the schema THIS version expects. 2_schema_reconcile
-- then compares the two and brings the live data up to it. Using the init files themselves as
-- the target means there is no second description of the schema to keep in step with them.

DO $$
BEGIN
    IF to_regnamespace('eucaim_cdm_ingestion_upgrade_live') IS NOT NULL
       OR to_regnamespace('eucaim_cdm_output_upgrade_live') IS NOT NULL THEN
        RAISE EXCEPTION 'schema upgrade: a *_upgrade_live schema already exists, a previous upgrade was left half done. Inspect it before running again';
    END IF;

    IF to_regnamespace('eucaim_cdm_ingestion') IS NOT NULL THEN
        ALTER SCHEMA eucaim_cdm_ingestion RENAME TO eucaim_cdm_ingestion_upgrade_live;
    END IF;
    IF to_regnamespace('eucaim_cdm_output') IS NOT NULL THEN
        ALTER SCHEMA eucaim_cdm_output RENAME TO eucaim_cdm_output_upgrade_live;
    END IF;
END $$;
