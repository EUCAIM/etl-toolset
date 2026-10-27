-- Schema upgrade, step 3 of 3: transform and export again the datasets of a rebuilt output
--
-- Run by scripts/reload_database.sh (group "schema") AFTER the upgrade transaction has
-- committed, and on its own: every dataset is transformed in its own transaction, so one that
-- fails does not undo the others, nor the upgrade. A dataset that fails stays queued in
-- public.schema_upgrade_pending and is retried the next time the group runs (or by hand with
-- CALL eucaim_etl_aux.transform_and_export_dataset_v001('<dataset>')).
--
-- transform_and_export_dataset_v001 is what the pipeline itself calls, so the CDM bundle in
-- the output folder is written again too, in the format of the new schema.

DO $$
DECLARE
    r  record;
    ok int := 0;
    ko int := 0;
BEGIN
    IF to_regclass('public.schema_upgrade_pending') IS NULL THEN
        RETURN;
    END IF;

    FOR r IN SELECT dataset_id FROM public.schema_upgrade_pending ORDER BY dataset_id LOOP
        BEGIN
            CALL eucaim_etl_aux.transform_and_export_dataset_v001(r.dataset_id);
            DELETE FROM public.schema_upgrade_pending WHERE dataset_id = r.dataset_id;
            RAISE NOTICE 'schema upgrade: dataset % transformed and exported again', r.dataset_id;
            ok := ok + 1;
        EXCEPTION WHEN OTHERS THEN
            RAISE WARNING 'schema upgrade: dataset % could not be transformed again, left queued: %', r.dataset_id, SQLERRM;
            ko := ko + 1;
        END;
        COMMIT;
    END LOOP;

    IF ok + ko > 0 THEN
        RAISE NOTICE 'schema upgrade: % dataset(s) regenerated, % still pending', ok, ko;
    END IF;
END $$;
