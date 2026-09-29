-- Step 7c Eucaim CDM: per dataset Markdown report
--
-- Writes <dataset_id>__report.md next to the CDM bundle, right after it is
-- exported. It is the file a node operator reads to know how their dataset
-- went, and the one they attach when asking for help.
--
-- It does not replace output_data/mapping_logs or output_data/etl_process_logs:
-- those stay as the raw trace. This is the reading of them, per dataset and per
-- run, which is what the raw files cannot give - they are fragments with no run
-- identity, and their id column restarts with the ingestion table, so the same
-- id means different rows in different runs.
--
-- PRIVACY. This file is meant to leave the node, so it carries no patient
-- identifier and nothing that identifies a person. What it does carry, because
-- a mapping cannot be fixed without it, is the distinct SOURCE VALUES that
-- failed to map - clinical vocabulary such as 'Not mutated' or 'Brother', never
-- tied to a patient. Every row it prints is an aggregate over the dataset.
-- Anything added here later has to hold that line.


-- Values written into the report come from the source data, so they can carry
-- anything. COPY in text format gives backslash a meaning of its own, and a
-- pipe or a newline would break the Markdown table it lands in.
CREATE OR REPLACE FUNCTION eucaim_etl_aux.md_cell(p_value text)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT coalesce(nullif(btrim(regexp_replace(coalesce(p_value, ''), '[\\|\t\r\n]+', ' ', 'g')), ''), '_(empty)_');
$$;


CREATE OR REPLACE PROCEDURE eucaim_etl_aux.report_dataset_v001(
    p_dataset_id text,
    p_output_dir text DEFAULT '/etl_output/cdm'
)
LANGUAGE plpgsql
SET search_path = eucaim_etl_aux, eucaim_cdm_output
AS $$
DECLARE
    v_md          text[] := ARRAY[]::text[];
    v_existing    text[];
    v_view        text;
    v_table       text;
    v_columns     text;
    v_rows        bigint;
    v_total       bigint := 0;
    v_header      text;
    v_first_line  text;
    v_status      text;
    v_manifest    text;
    v_bad_headers integer := 0;
    v_missing     integer := 0;
    v_empty       text[] := ARRAY[]::text[];
    v_absent      text[] := ARRAY[]::text[];
    v_producible  boolean;
    v_mapped      bigint;
    v_unmapped    bigint;
    v_since       text;
    v_shown       integer := 0;
    r             record;
BEGIN
    IF p_dataset_id IS NULL OR p_dataset_id !~ '^[A-Za-z0-9_-]{1,150}$' THEN
        RAISE EXCEPTION 'report_dataset: dataset id % is not a plain identifier', p_dataset_id;
    END IF;
    IF p_output_dir IS NULL OR left(p_output_dir, 1) <> '/' OR p_output_dir LIKE '%..%' THEN
        RAISE EXCEPTION 'report_dataset: % is not an absolute path without parent references', p_output_dir;
    END IF;

    SELECT coalesce(array_agg(f), '{}') INTO v_existing
    FROM pg_ls_dir(p_output_dir) f
    WHERE starts_with(f, p_dataset_id || '__') AND f LIKE '%.csv';

    -- The manifest's own verdict, read back from disk rather than assumed
    BEGIN
        v_manifest := pg_read_file(p_output_dir || '/' || p_dataset_id || '__manifest.csv', 0, 8192);
        v_status   := split_part(split_part(v_manifest, E'\n', 2), ',', 3);
    EXCEPTION WHEN OTHERS THEN
        v_status := 'no manifest';
    END;

    ---------------------------------------------------------------- heading
    v_md := v_md || ARRAY[
        '# EUCAIM ETL report',
        '',
        '| | |',
        '|---|---|',
        '| Dataset | `' || p_dataset_id || '` |',
        '| Title | ' || eucaim_etl_aux.md_cell((SELECT dataset_title FROM eucaim_cdm_output.dataset WHERE dataset_id = p_dataset_id)) || ' |',
        '| Generated | ' || to_char(now(), 'YYYY-MM-DD HH24:MI:SS') || ' |',
        '| Bundle status | **' || v_status || '** |',
        '| CDM | clinical v4.2, imaging v4.1 |',
        '',
        '> This report contains no patient identifier and no identifying data. Every',
        '> figure below is an aggregate over the dataset. The source values listed in',
        '> section 3 are the vocabulary of the source file, never linked to a patient.',
        ''];

    ------------------------------------------------- 1. what was exported
    v_md := v_md || ARRAY['## 1. What was exported', '', '| CDM table | Rows |', '|---|---:|'];

    FOR v_view IN
        SELECT table_name FROM information_schema.views
        WHERE table_schema = 'eucaim_cdm_output' AND table_name LIKE 'v_export\_%'
        ORDER BY table_name
    LOOP
        v_table := substring(v_view from 10);
        EXECUTE format('SELECT count(*) FROM eucaim_cdm_output.%I WHERE export_dataset_id = %L', v_view, p_dataset_id)
        INTO v_rows;

        IF v_rows > 0 THEN
            v_md    := v_md || ('| ' || v_table || ' | ' || v_rows || ' |');
            v_total := v_total + v_rows;

            -- 2. does the file on disk say the same thing?
            IF NOT (p_dataset_id || '__' || v_table || '.csv') = ANY(v_existing) THEN
                v_missing := v_missing + 1;
                v_md := v_md || ('| ' || v_table || ' | **file missing** |');
            ELSE
                SELECT string_agg(column_name, ',' ORDER BY ordinal_position) INTO v_columns
                FROM information_schema.columns
                WHERE table_schema = 'eucaim_cdm_output' AND table_name = v_view
                  AND column_name <> 'export_dataset_id';

                v_first_line := split_part(
                    pg_read_file(p_output_dir || '/' || p_dataset_id || '__' || v_table || '.csv', 0, 8192),
                    E'\n', 1);
                v_header := rtrim(v_first_line, E'\r');
                IF v_header <> v_columns THEN
                    v_bad_headers := v_bad_headers + 1;
                END IF;
            END IF;
        ELSE
            -- keep it for section 4, where the distinction is made
            SELECT EXISTS (
                SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
                WHERE n.nspname = 'eucaim_etl_aux' AND p.proname = 'transform_dataset_v001'
                  AND p.prosrc ~* ('INSERT\s+INTO\s+eucaim_cdm_output\.' || v_table || '\M')
            ) INTO v_producible;

            IF v_producible THEN
                v_empty := v_empty || v_table;
            ELSE
                v_absent := v_absent || v_table;
            END IF;
        END IF;
    END LOOP;

    v_md := v_md || ARRAY['| **Total** | **' || v_total || '** |', ''];

    ---------------------------------------------------------- 2. integrity
    v_md := v_md || ARRAY['## 2. Integrity', ''];
    IF v_status <> 'complete' THEN
        v_md := v_md || ('- ❌ the manifest says `' || v_status || '`: this bundle is not complete and must not be used');
    ELSE
        v_md := v_md || '- ✅ the manifest declares the bundle complete'::text;
    END IF;
    IF v_missing > 0 THEN
        v_md := v_md || ('- ❌ ' || v_missing || ' table(s) have rows but no file on disk');
    END IF;
    IF v_bad_headers > 0 THEN
        v_md := v_md || ('- ❌ ' || v_bad_headers || ' file(s) have a header that is not the CDM column list of their table');
    ELSIF v_missing = 0 THEN
        v_md := v_md || '- ✅ every exported file was read back and its header is the CDM column list of its table'::text;
    END IF;
    v_md := v_md || ''::text;

    ----------------------------------------------------- 3. mapping quality
    SELECT count(*) FILTER (WHERE coalesce(codeInEUCAIM, '') <> ''),
           count(*) FILTER (WHERE coalesce(codeInEUCAIM, '') =  ''),
           to_char(min(mappingTimestamp::timestamp), 'YYYY-MM-DD HH24:MI')
    INTO v_mapped, v_unmapped, v_since
    FROM eucaim_cdm_ingestion.MappedCodeableConceptsResults
    WHERE datasetId = p_dataset_id;

    v_md := v_md || ARRAY['## 3. Mapping quality', ''];

    IF coalesce(v_mapped, 0) + coalesce(v_unmapped, 0) = 0 THEN
        v_md := v_md || ARRAY['No mapping result recorded for this dataset.', ''];
    ELSE
        v_md := v_md || ARRAY[
            '| | |',
            '|---|---:|',
            '| Source values mapped to a EUCAIM code | ' || v_mapped || ' |',
            '| Source values with **no** EUCAIM code | ' || v_unmapped || ' |',
            '| Share unmapped | **' || round(100.0 * v_unmapped / (v_mapped + v_unmapped), 1) || '%** |',
            '| Oldest mapping recorded | ' || coalesce(v_since, '-') || ' |',
            ''];

        IF v_unmapped > 0 THEN
            v_md := v_md || ARRAY[
                'Every source value below reached the mapping and came out without a code, so',
                'the data behind it is not in the CDM output. Each row is a distinct value and',
                'how many times it appeared.',
                '',
                '| Source column | Source value | Times |',
                '|---|---|---:|'];

            FOR r IN
                SELECT propertyNameOriginal AS col, originalValue AS val, count(*) AS n
                FROM eucaim_cdm_ingestion.MappedCodeableConceptsResults
                WHERE datasetId = p_dataset_id AND coalesce(codeInEUCAIM, '') = ''
                GROUP BY 1, 2
                ORDER BY count(*) DESC, 1, 2
                LIMIT 100
            LOOP
                v_md    := v_md || ('| ' || eucaim_etl_aux.md_cell(r.col) || ' | ' || eucaim_etl_aux.md_cell(r.val) || ' | ' || r.n || ' |');
                v_shown := v_shown + 1;
            END LOOP;

            IF v_shown = 100 THEN
                v_md := v_md || ARRAY['', '_Only the 100 most frequent are listed; output_data/mapping_logs has them all._'];
            END IF;
            v_md := v_md || ''::text;
        END IF;
    END IF;

    ----------------------------------------------------- 4. CDM coverage
    v_md := v_md || ARRAY['## 4. CDM coverage', ''];
    IF array_length(v_empty, 1) > 0 THEN
        v_md := v_md || ARRAY[
            'The ETL knows how to fill these, and this dataset brought no data for them:',
            '',
            '- ' || array_to_string(v_empty, ', '),
            ''];
    END IF;
    IF array_length(v_absent, 1) > 0 THEN
        v_md := v_md || ARRAY[
            'No coverage yet in current branch:',
            '',
            '- ' || array_to_string(v_absent, ', '),
            ''];
    END IF;

    ------------------------------------------------------- 5. pipeline log
    v_md := v_md || ARRAY['## 5. Pipeline log', ''];
    IF NOT EXISTS (SELECT 1 FROM eucaim_cdm_ingestion.ProcessLog WHERE datasetId = p_dataset_id) THEN
        v_md := v_md || ARRAY['No pipeline step recorded for this dataset.', ''];
    ELSE
        v_md := v_md || ARRAY['| Level | Steps |', '|---|---:|'];
        FOR r IN
            SELECT level, count(*) AS n FROM eucaim_cdm_ingestion.ProcessLog
            WHERE datasetId = p_dataset_id GROUP BY level ORDER BY level
        LOOP
            v_md := v_md || ('| ' || eucaim_etl_aux.md_cell(r.level) || ' | ' || r.n || ' |');
        END LOOP;
        v_md := v_md || ''::text;

        IF EXISTS (SELECT 1 FROM eucaim_cdm_ingestion.ProcessLog
                   WHERE datasetId = p_dataset_id AND level <> 'INFO') THEN
            v_md := v_md || ARRAY['| When | Stage | Step | Level | Message |', '|---|---|---|---|---|'];
            FOR r IN
                SELECT to_char(timestamp, 'YYYY-MM-DD HH24:MI:SS') AS ts, pipelineStage AS stage,
                       stepName AS step, level, message
                FROM eucaim_cdm_ingestion.ProcessLog
                WHERE datasetId = p_dataset_id AND level <> 'INFO'
                ORDER BY timestamp DESC
                LIMIT 50
            LOOP
                v_md := v_md || ('| ' || r.ts || ' | ' || eucaim_etl_aux.md_cell(r.stage) || ' | '
                              || eucaim_etl_aux.md_cell(r.step) || ' | ' || eucaim_etl_aux.md_cell(r.level)
                              || ' | ' || eucaim_etl_aux.md_cell(r.message) || ' |');
            END LOOP;
        ELSE
            -- Worth saying plainly: right now the flows only ever write INFO rows
            -- here, so a clean log is not by itself evidence that nothing failed.
            v_md := v_md || ARRAY[
                'No warning or error recorded for this dataset. Note that the pipeline',
                'currently only writes INFO rows to this log, so failures are found in',
                'output_data/etl_process_logs/etl-errors.log rather than here.',
                ''];
        END IF;
    END IF;

    v_md := v_md || ARRAY['', '---', '', 'Generated by `eucaim_etl_aux.report_dataset_v001`. Checks the bundle against the',
                          'database it came from; `scripts/check_cdm_bundle.sh` runs the same comparison on demand.'];

    EXECUTE format(
        'COPY (SELECT line FROM unnest(%L::text[]) WITH ORDINALITY t(line, i) ORDER BY i) TO %L WITH (FORMAT text)',
        v_md, p_output_dir || '/' || p_dataset_id || '__report.md');

    CALL eucaim_etl_aux.insert_log_v001(
        p_dataset_id || '__report.md', p_dataset_id, 'cdm_output', 'export', '2',
        'report_dataset', 'INFO', 'OK',
        format('Report written, %s rows exported, %s source values unmapped', v_total, coalesce(v_unmapped, 0)));
END;
$$;


-- What the pipeline calls: rebuilding the output schema, writing the bundle and
-- writing the report are one step, so the files on disk can never describe a
-- state of the database that has already moved on.
--
-- The report is the one part allowed to fail on its own. COPY does not roll back
-- with the transaction, so a report that raised after a good export would undo
-- the output schema while leaving a bundle on disk still claiming to be
-- complete - the deliverable saying one thing and the database another, which is
-- the single worst outcome here. The deliverable is the bundle; the report is a
-- reading of it, and losing the reading is not worth losing the bundle.
CREATE OR REPLACE PROCEDURE eucaim_etl_aux.transform_and_export_dataset_v001(p_dataset_id text)
LANGUAGE plpgsql
AS $$
BEGIN
    CALL eucaim_etl_aux.transform_dataset_v001(p_dataset_id);
    CALL eucaim_etl_aux.export_dataset_to_csv_v001(p_dataset_id);

    BEGIN
        CALL eucaim_etl_aux.report_dataset_v001(p_dataset_id);
    EXCEPTION WHEN OTHERS THEN
        CALL eucaim_etl_aux.insert_log_v001(
            p_dataset_id || '__report.md', p_dataset_id, 'cdm_output', 'export', '2',
            'report_dataset', 'WARN', 'ERROR',
            'The bundle was exported but its report could not be written: ' || SQLERRM);
    END;
END;
$$;
