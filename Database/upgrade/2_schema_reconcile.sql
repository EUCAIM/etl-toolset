-- Schema upgrade, step 2 of 3: bring the live schemas up to the ones this version expects
--
-- Runs right after 1_schema_set_aside.sql and the init files 2, 3 and 3z, in the same
-- transaction, so at this point:
--   eucaim_cdm_ingestion / eucaim_cdm_output                    empty, built by THIS version
--   eucaim_cdm_ingestion_upgrade_live / eucaim_cdm_output_upgrade_live   the node's data
--
-- Ingestion holds data that only exists here (re-creating it means ingesting every file
-- again), so it is reconciled in place, column by column:
--   * a table that is missing is moved over from the new copy, exactly as the init file made it
--   * a column that is missing is added, with its type, default and identity
--   * a column whose type changed is altered. The cast is the assignment one, so a value that
--     no longer fits (a longer text, a bigger number) stops the upgrade instead of being cut.
--     A NUMERIC that would lose decimals stops it too: that cast rounds without complaining.
--   * NOT NULL is dropped where the new version relaxed it, and set where it was added only
--     if no row breaks it (otherwise it is reported and left as it was)
--   * a column the new version no longer has is kept with its data, and only loses its
--     NOT NULL, so the flows (which no longer fill it) can still write the row
--   * a primary key that changed is replaced. The flows UPSERT on it.
-- A column RENAMED in 2_init looks here like one column gone and a new one added: the data
-- stays in the old one and the new one starts empty. If a rename has to carry the data, write
-- it explicitly before the generic part below.
--
-- Output, on the other hand, is a projection of ingestion: transform_dataset_v001 deletes a
-- dataset from it and builds it again. So when its structure differs at all from the one this
-- version expects, the old one is dropped whole and the new one kept, and every dataset it
-- held is queued in public.schema_upgrade_pending. 3_schema_regenerate_output.sql, run after
-- this transaction commits, transforms and exports them again one by one.
--
-- Every change is reported with RAISE NOTICE.

CREATE TABLE IF NOT EXISTS public.schema_upgrade_pending (
    dataset_id VARCHAR(150) PRIMARY KEY,
    queued_at  TIMESTAMP DEFAULT now()
);

-- the structure of every table of a schema as text, without the schema name, so the live
-- output schema and the one just built can be compared as a whole
CREATE FUNCTION pg_temp.upgrade_schema_signature(p_schema text)
RETURNS text
LANGUAGE sql
AS $$
    SELECT coalesce(string_agg(line, E'\n' ORDER BY line), '')
    FROM (
        SELECT c.relname || '.' || a.attname || ' ' || format_type(a.atttypid, a.atttypmod)
               || CASE WHEN a.attnotnull THEN ' NOT NULL' ELSE '' END
               || CASE a.attidentity WHEN 'a' THEN ' IDENTITY ALWAYS' WHEN 'd' THEN ' IDENTITY BY DEFAULT' ELSE '' END
               || coalesce(' DEFAULT ' || pg_get_expr(d.adbin, d.adrelid), '') AS line
        FROM pg_class c
        JOIN pg_attribute a ON a.attrelid = c.oid AND a.attnum > 0 AND NOT a.attisdropped
        LEFT JOIN pg_attrdef d ON d.adrelid = c.oid AND d.adnum = a.attnum
        WHERE c.relnamespace = p_schema::regnamespace AND c.relkind = 'r'
        UNION ALL
        SELECT c.relname || ' ' || con.contype::text || ' '
               || replace(pg_get_constraintdef(con.oid), p_schema || '.', '')
        FROM pg_constraint con
        JOIN pg_class c ON c.oid = con.conrelid
        WHERE c.relnamespace = p_schema::regnamespace AND c.relkind = 'r'
    ) s;
$$;

-- DROP SCHEMA ... CASCADE lists every table it takes with it, which would bury the changes
-- reported below
CREATE FUNCTION pg_temp.upgrade_drop_schema(p_schema text)
RETURNS void
LANGUAGE plpgsql
SET client_min_messages = warning
AS $$
BEGIN
    EXECUTE format('DROP SCHEMA %I CASCADE', p_schema);
END;
$$;

DO $$
DECLARE
    ing      CONSTANT text := 'eucaim_cdm_ingestion';
    ing_new  CONSTANT text := 'eucaim_cdm_ingestion_upgrade_target';
    t        record;
    col      record;
    live_col record;
    live_pk  record;
    new_pk   text[];
    has_rows boolean;
    has_null boolean;
    old_p int; old_s int; new_p int; new_s int;
    v_changes int := 0;
BEGIN
    ---------------------------------------------------------------------------------------
    -- put the names back: the data under its real name, the new copy aside
    ALTER SCHEMA eucaim_cdm_ingestion RENAME TO eucaim_cdm_ingestion_upgrade_target;
    ALTER SCHEMA eucaim_cdm_output    RENAME TO eucaim_cdm_output_upgrade_target;

    IF to_regnamespace('eucaim_cdm_ingestion_upgrade_live') IS NULL THEN
        -- nothing was there before: the new one simply becomes the live one
        ALTER SCHEMA eucaim_cdm_ingestion_upgrade_target RENAME TO eucaim_cdm_ingestion;
        RAISE NOTICE 'schema upgrade: eucaim_cdm_ingestion did not exist, created';
    ELSE
        ALTER SCHEMA eucaim_cdm_ingestion_upgrade_live RENAME TO eucaim_cdm_ingestion;

        -- reported before the loop below moves the missing ones over
        FOR t IN
            SELECT c.relname FROM pg_class c
            WHERE c.relnamespace = ing::regnamespace AND c.relkind = 'r'
              AND to_regclass(format('%I.%I', ing_new, c.relname)) IS NULL
        LOOP
            RAISE NOTICE 'schema upgrade: %.% is no longer used by this version, kept as it is', ing, t.relname;
        END LOOP;

        -----------------------------------------------------------------------------------
        -- ingestion, table by table
        FOR t IN
            SELECT c.oid, c.relname
            FROM pg_class c
            WHERE c.relnamespace = ing_new::regnamespace AND c.relkind = 'r'
            ORDER BY c.relname
        LOOP
            IF to_regclass(format('%I.%I', ing, t.relname)) IS NULL THEN
                EXECUTE format('ALTER TABLE %I.%I SET SCHEMA %I', ing_new, t.relname, ing);
                RAISE NOTICE 'schema upgrade: %.% created', ing, t.relname;
                v_changes := v_changes + 1;
                CONTINUE;
            END IF;

            EXECUTE format('SELECT EXISTS (SELECT 1 FROM %I.%I)', ing, t.relname) INTO has_rows;

            -- columns this version expects
            FOR col IN
                SELECT a.attname, format_type(a.atttypid, a.atttypmod) AS typ, a.atttypid, a.atttypmod,
                       a.attnotnull, a.attidentity, pg_get_expr(d.adbin, d.adrelid) AS def
                FROM pg_attribute a
                LEFT JOIN pg_attrdef d ON d.adrelid = a.attrelid AND d.adnum = a.attnum
                WHERE a.attrelid = t.oid AND a.attnum > 0 AND NOT a.attisdropped
                ORDER BY a.attnum
            LOOP
                SELECT a.attname, format_type(a.atttypid, a.atttypmod) AS typ, a.atttypid, a.atttypmod,
                       a.attnotnull, a.attidentity, pg_get_expr(d.adbin, d.adrelid) AS def
                INTO live_col
                FROM pg_attribute a
                LEFT JOIN pg_attrdef d ON d.adrelid = a.attrelid AND d.adnum = a.attnum
                WHERE a.attrelid = format('%I.%I', ing, t.relname)::regclass
                  AND a.attname = col.attname AND a.attnum > 0 AND NOT a.attisdropped;

                IF NOT FOUND THEN
                    EXECUTE format('ALTER TABLE %I.%I ADD COLUMN %I %s%s%s%s', ing, t.relname, col.attname, col.typ,
                        CASE col.attidentity WHEN 'a' THEN ' GENERATED ALWAYS AS IDENTITY'
                                             WHEN 'd' THEN ' GENERATED BY DEFAULT AS IDENTITY' ELSE '' END,
                        coalesce(' DEFAULT ' || col.def, ''),
                        -- existing rows would get NULL: only safe with a default or no rows
                        CASE WHEN col.attnotnull AND col.attidentity = '' AND (col.def IS NOT NULL OR NOT has_rows)
                             THEN ' NOT NULL' ELSE '' END);
                    RAISE NOTICE 'schema upgrade: %.%.% added (%)', ing, t.relname, col.attname, col.typ;
                    v_changes := v_changes + 1;
                    CONTINUE;
                END IF;

                IF live_col.typ <> col.typ THEN
                    IF live_col.atttypid = 'numeric'::regtype AND col.atttypid = 'numeric'::regtype
                       AND live_col.atttypmod >= 0 AND col.atttypmod >= 0 THEN
                        old_p := ((live_col.atttypmod - 4) >> 16) & 65535;  old_s := (live_col.atttypmod - 4) & 65535;
                        new_p := ((col.atttypmod - 4) >> 16) & 65535;       new_s := (col.atttypmod - 4) & 65535;
                        IF new_s < old_s THEN
                            RAISE EXCEPTION 'schema upgrade: %.%.% would go from % to %, which rounds the stored decimals. Not applied',
                                ing, t.relname, col.attname, live_col.typ, col.typ;
                        END IF;
                    END IF;
                    EXECUTE format('ALTER TABLE %I.%I ALTER COLUMN %I TYPE %s', ing, t.relname, col.attname, col.typ);
                    RAISE NOTICE 'schema upgrade: %.%.% % -> %', ing, t.relname, col.attname, live_col.typ, col.typ;
                    v_changes := v_changes + 1;
                END IF;

                IF live_col.attnotnull AND NOT col.attnotnull THEN
                    EXECUTE format('ALTER TABLE %I.%I ALTER COLUMN %I DROP NOT NULL', ing, t.relname, col.attname);
                    RAISE NOTICE 'schema upgrade: %.%.% now accepts NULL', ing, t.relname, col.attname;
                    v_changes := v_changes + 1;
                ELSIF col.attnotnull AND NOT live_col.attnotnull AND col.attidentity = '' THEN
                    EXECUTE format('SELECT EXISTS (SELECT 1 FROM %I.%I WHERE %I IS NULL)', ing, t.relname, col.attname) INTO has_null;
                    IF has_null THEN
                        RAISE NOTICE 'schema upgrade: %.%.% should be NOT NULL but has NULL rows, left as it was',
                            ing, t.relname, col.attname;
                    ELSE
                        EXECUTE format('ALTER TABLE %I.%I ALTER COLUMN %I SET NOT NULL', ing, t.relname, col.attname);
                        RAISE NOTICE 'schema upgrade: %.%.% now NOT NULL', ing, t.relname, col.attname;
                        v_changes := v_changes + 1;
                    END IF;
                END IF;

                IF col.attidentity = '' AND live_col.attidentity = ''
                   AND col.def IS DISTINCT FROM live_col.def AND col.def IS NOT NULL THEN
                    EXECUTE format('ALTER TABLE %I.%I ALTER COLUMN %I SET DEFAULT %s', ing, t.relname, col.attname, col.def);
                    RAISE NOTICE 'schema upgrade: %.%.% default %', ing, t.relname, col.attname, col.def;
                    v_changes := v_changes + 1;
                END IF;
            END LOOP;

            -- columns this version no longer has: kept with their data, but they must not
            -- stop the flows from writing a row that leaves them empty
            FOR live_col IN
                SELECT a.attname
                FROM pg_attribute a
                WHERE a.attrelid = format('%I.%I', ing, t.relname)::regclass
                  AND a.attnum > 0 AND NOT a.attisdropped
                  AND a.attnotnull AND a.attidentity = ''
                  AND NOT EXISTS (SELECT 1 FROM pg_attrdef d WHERE d.adrelid = a.attrelid AND d.adnum = a.attnum)
                  AND NOT EXISTS (SELECT 1 FROM pg_attribute n
                                  WHERE n.attrelid = t.oid AND n.attname = a.attname AND NOT n.attisdropped)
                  AND NOT EXISTS (SELECT 1 FROM pg_constraint pk
                                  WHERE pk.conrelid = a.attrelid AND pk.contype = 'p' AND a.attnum = ANY (pk.conkey))
            LOOP
                EXECUTE format('ALTER TABLE %I.%I ALTER COLUMN %I DROP NOT NULL', ing, t.relname, live_col.attname);
                RAISE NOTICE 'schema upgrade: %.%.% is no longer used, kept but now accepts NULL', ing, t.relname, live_col.attname;
                v_changes := v_changes + 1;
            END LOOP;

            -- primary key: the flows UPSERT on it
            SELECT array_agg(a.attname::text ORDER BY k.ord) INTO new_pk
            FROM pg_constraint con
            CROSS JOIN LATERAL unnest(con.conkey) WITH ORDINALITY AS k(attnum, ord)
            JOIN pg_attribute a ON a.attrelid = con.conrelid AND a.attnum = k.attnum
            WHERE con.conrelid = t.oid AND con.contype = 'p';

            SELECT con.conname, array_agg(a.attname::text ORDER BY k.ord) AS cols INTO live_pk
            FROM pg_constraint con
            CROSS JOIN LATERAL unnest(con.conkey) WITH ORDINALITY AS k(attnum, ord)
            JOIN pg_attribute a ON a.attrelid = con.conrelid AND a.attnum = k.attnum
            WHERE con.conrelid = format('%I.%I', ing, t.relname)::regclass AND con.contype = 'p'
            GROUP BY con.conname;

            IF new_pk IS DISTINCT FROM live_pk.cols THEN
                IF live_pk.conname IS NOT NULL THEN
                    EXECUTE format('ALTER TABLE %I.%I DROP CONSTRAINT %I', ing, t.relname, live_pk.conname);
                END IF;
                IF new_pk IS NOT NULL THEN
                    EXECUTE format('ALTER TABLE %I.%I ADD PRIMARY KEY (%s)', ing, t.relname,
                                   (SELECT string_agg(quote_ident(c), ', ') FROM unnest(new_pk) c));
                END IF;
                RAISE NOTICE 'schema upgrade: %.% primary key % -> %', ing, t.relname, live_pk.cols, new_pk;
                v_changes := v_changes + 1;
            END IF;
        END LOOP;

        PERFORM pg_temp.upgrade_drop_schema('eucaim_cdm_ingestion_upgrade_target');
        RAISE NOTICE 'schema upgrade: eucaim_cdm_ingestion, % change(s)', v_changes;
    END IF;

    ---------------------------------------------------------------------------------------
    -- output: kept if it is already what this version expects, rebuilt otherwise
    IF to_regnamespace('eucaim_cdm_output_upgrade_live') IS NULL THEN
        ALTER SCHEMA eucaim_cdm_output_upgrade_target RENAME TO eucaim_cdm_output;
        RAISE NOTICE 'schema upgrade: eucaim_cdm_output did not exist, created';
    ELSIF pg_temp.upgrade_schema_signature('eucaim_cdm_output_upgrade_live')
          = pg_temp.upgrade_schema_signature('eucaim_cdm_output_upgrade_target') THEN
        PERFORM pg_temp.upgrade_drop_schema('eucaim_cdm_output_upgrade_target');
        ALTER SCHEMA eucaim_cdm_output_upgrade_live RENAME TO eucaim_cdm_output;
        RAISE NOTICE 'schema upgrade: eucaim_cdm_output already up to date';
    ELSE
        IF to_regclass('eucaim_cdm_output_upgrade_live.dataset') IS NOT NULL THEN
            INSERT INTO public.schema_upgrade_pending (dataset_id)
            SELECT o.dataset_id
            FROM eucaim_cdm_output_upgrade_live.dataset o
            JOIN eucaim_cdm_ingestion.dataset i ON i.identifier = o.dataset_id
            ON CONFLICT DO NOTHING;
        END IF;
        PERFORM pg_temp.upgrade_drop_schema('eucaim_cdm_output_upgrade_live');
        ALTER SCHEMA eucaim_cdm_output_upgrade_target RENAME TO eucaim_cdm_output;
        RAISE NOTICE 'schema upgrade: eucaim_cdm_output rebuilt, % dataset(s) queued to be transformed again',
            (SELECT count(*) FROM public.schema_upgrade_pending);
    END IF;
END $$;
