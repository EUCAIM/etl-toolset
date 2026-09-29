-- Step 7b Eucaim CDM: CSV export of the output schema
--
-- Writes the CDM bundle of one dataset as a set of CSV files, straight from
-- eucaim_cdm_output with a server side COPY. The point is that the files and
-- the database say the same thing because they come from the same place: the
-- export reads what transform_dataset_v001 wrote, and reads nothing else.
--
-- What to export is not listed anywhere here. The procedure asks the catalogue
-- for every eucaim_cdm_output.v_export_* view and exports each one, so a new
-- CDM table reaches the bundle by adding its view to step 7a and nothing else.
--
-- Files land flat, as <dataset_id>__<table>.csv, rather than in a directory per
-- dataset: COPY cannot create a directory and PL/pgSQL cannot either, so a
-- layout with subdirectories would need something outside the database to make
-- them first.
--
-- A table with no rows for this dataset gets no file. Which tables the model has
-- is the manifest's job, and it lists all of them with their count, so an empty
-- file would only repeat what the manifest already says - while claiming this
-- node produces data it has no way of producing: five CDM tables (adverse_event,
-- comorbidities, medical_history, segmentation_series, segment) have no ingestion
-- table behind them and would ship empty in every bundle forever.
--
-- COPY can create and overwrite a file but not delete one, so a table dropping
-- back to zero rows would leave its previous file on disk, still full of rows
-- that are no longer true. That is why the run lists the directory first: a file
-- already there is rewritten even at zero rows, which leaves it holding nothing
-- but its header. Nothing is ever left saying something the database does not.
--
-- Completion is declared by <dataset_id>__manifest.csv, which is rewritten as
-- in_progress before the first table and as complete after the last one. COPY
-- is not transactional against the filesystem, so a run that dies halfway
-- leaves a bundle whose files are part old and part new; the manifest is what
-- tells a consumer that what it is reading is a whole bundle. Read it first.
--
-- Requires ./output_data mounted into the nifi-postgres container (see
-- docker-compose.yaml) and the cdm subdirectory created by startup.sh.
--
-- The files belong to the database process, not to the host user, and COPY
-- overwrites in place. Editing one of them from outside makes it the editor's
-- file and the next export can no longer write it: it raises, the manifest is
-- left saying in_progress, and no consumer trusts the bundle until someone
-- deletes the file and exports again (deleting works, the directory is 777,
-- what fails is overwriting someone else's file). To look at a bundle or change
-- one, copy it somewhere else first.


CREATE OR REPLACE PROCEDURE eucaim_etl_aux.export_dataset_to_csv_v001(
    p_dataset_id text,
    p_output_dir text DEFAULT '/etl_output/cdm'
)
LANGUAGE plpgsql
SET search_path = eucaim_etl_aux, eucaim_cdm_output
AS $$
DECLARE
    v_view        text;
    v_table       text;
    v_columns     text;
    v_path        text;
    v_rows        bigint;
    v_exported_at timestamptz := now();
    v_total       bigint := 0;
    v_tables      integer := 0;
    v_existing    text[];
    v_filename    text;
BEGIN
    -- Both values end up inside a filesystem path, so neither may carry a
    -- separator or a parent reference. Without this, a dataset identifier is
    -- enough to write a file anywhere the server process can reach.
    IF p_dataset_id IS NULL OR p_dataset_id !~ '^[A-Za-z0-9_-]{1,150}$' THEN
        RAISE EXCEPTION 'export_dataset_to_csv: refusing to export, dataset id % is not a plain identifier', p_dataset_id;
    END IF;

    IF p_output_dir IS NULL OR left(p_output_dir, 1) <> '/' OR p_output_dir LIKE '%..%' THEN
        RAISE EXCEPTION 'export_dataset_to_csv: refusing to export, % is not an absolute path without parent references', p_output_dir;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM eucaim_cdm_output.dataset WHERE dataset_id = p_dataset_id) THEN
        RAISE EXCEPTION 'export_dataset_to_csv: dataset % has no rows in eucaim_cdm_output, run transform_dataset_v001 first', p_dataset_id;
    END IF;

    -- A temp table rather than an array, so the manifest is written with the
    -- same COPY as everything else. Dropped first because a second CALL in the
    -- same session would otherwise find the previous one still there.
    IF to_regclass('pg_temp.export_manifest') IS NOT NULL THEN
        DROP TABLE pg_temp.export_manifest;
    END IF;
    CREATE TEMP TABLE export_manifest (
        dataset_id  text,
        exported_at timestamptz,
        status      text,
        cdm_table   text,
        row_count   bigint
    );

    -- Marks the bundle as being rewritten before a single file changes, so a
    -- run that fails halfway cannot leave the previous manifest standing over
    -- files that no longer match it.
    INSERT INTO export_manifest VALUES (p_dataset_id, v_exported_at, 'in_progress', NULL, NULL);
    EXECUTE format(
        'COPY (SELECT dataset_id, exported_at, status, cdm_table, row_count FROM export_manifest) TO %L WITH (FORMAT csv, HEADER true)',
        p_output_dir || '/' || p_dataset_id || '__manifest.csv');
    DELETE FROM export_manifest;

    -- What this dataset already has on disk, so a table that no longer has rows
    -- can be emptied instead of being left behind with the previous run's.
    SELECT coalesce(array_agg(f), '{}')
    INTO v_existing
    FROM pg_ls_dir(p_output_dir) f
    WHERE starts_with(f, p_dataset_id || '__') AND f LIKE '%.csv';

    FOR v_view IN
        SELECT table_name
        FROM information_schema.views
        WHERE table_schema = 'eucaim_cdm_output'
          AND table_name LIKE 'v_export\_%'
        ORDER BY table_name
    LOOP
        v_table := substring(v_view from 10);   -- strips the v_export_ prefix

        -- The CDM header, which is the view's columns minus the one this export
        -- added to know which dataset the row belongs to.
        SELECT string_agg(quote_ident(column_name), ', ' ORDER BY ordinal_position)
        INTO v_columns
        FROM information_schema.columns
        WHERE table_schema = 'eucaim_cdm_output'
          AND table_name = v_view
          AND column_name <> 'export_dataset_id';

        EXECUTE format('SELECT count(*) FROM eucaim_cdm_output.%I WHERE export_dataset_id = %L', v_view, p_dataset_id)
        INTO v_rows;

        v_filename := p_dataset_id || '__' || v_table || '.csv';
        v_path     := p_output_dir || '/' || v_filename;

        -- Written when the table has rows, and also when it has none but a file
        -- from an earlier run is still sitting there: that one is overwritten
        -- down to its header rather than left holding rows that no longer exist.
        IF v_rows > 0 OR v_filename = ANY(v_existing) THEN
            EXECUTE format(
                'COPY (SELECT %s FROM eucaim_cdm_output.%I WHERE export_dataset_id = %L) TO %L WITH (FORMAT csv, HEADER true)',
                v_columns, v_view, p_dataset_id, v_path);
        END IF;

        INSERT INTO export_manifest VALUES (p_dataset_id, v_exported_at, 'complete', v_table, v_rows);
        v_total  := v_total + v_rows;
        v_tables := v_tables + 1;
    END LOOP;

    IF v_tables = 0 THEN
        RAISE EXCEPTION 'export_dataset_to_csv: no v_export_* view found in eucaim_cdm_output, nothing was exported';
    END IF;

    EXECUTE format(
        'COPY (SELECT dataset_id, exported_at, status, cdm_table, row_count FROM export_manifest ORDER BY cdm_table) TO %L WITH (FORMAT csv, HEADER true)',
        p_output_dir || '/' || p_dataset_id || '__manifest.csv');

    CALL eucaim_etl_aux.insert_log_v001(
        p_dataset_id || '__manifest.csv', p_dataset_id, 'cdm_output', 'export', '1',
        'export_dataset_to_csv', 'INFO', 'OK',
        format('Exported %s rows over %s CDM tables to %s', v_total, v_tables, p_output_dir));

    DROP TABLE pg_temp.export_manifest;
END;
$$;


-- transform_and_export_dataset_v001, which is what the pipeline actually calls,
-- lives in step 7c: it chains this export with the report, and keeping one
-- definition avoids an edit here silently losing to the later one.
