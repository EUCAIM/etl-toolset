-- How the DICOM studies of each dataset got (or did not get) their imaging timepoint and the link to
-- an imaging procedure, in the ingestion schema. It answers "why is ImagingTimepoint null in
-- eucaim_cdm_ingestion.imagestudy" and "why are procedure and image_* missing from the CDM".
--
-- Every figure is an aggregate: no patient or study identifier is printed, so the output can be
-- shared as it is. To see the study UIDs of the unlinked studies, to compare them by hand with the
-- timepoints csv, run it yourself with the variable list_uids set, and do not forward that output:
--   docker exec -i nifi-postgres psql -U postgres -d eucaim-etl-db -v list_uids=1 \
--       -v dataset="'<dataset_id>'" -f - < scripts/check_imaging_timepoints.sql

\if :{?dataset}
\else
  \set dataset NULL
\endif


-- 1. Studies per dataset: how many have a timepoint and how many are linked to a procedure.
--    "linked" means the procedure it points to exists in the ingestion schema for the same patient.
SELECT s.datasetidentifier                                        AS dataset_id,
       COUNT(*)                                                   AS studies,
       COUNT(*) FILTER (WHERE s.imagingtimepoint IS NOT NULL)     AS with_timepoint,
       COUNT(*) FILTER (WHERE EXISTS (
               SELECT 1
               FROM eucaim_cdm_ingestion.imagingprocedure ip
               JOIN eucaim_cdm_ingestion.primarycancercondition pcc
                 ON pcc.identifier = ip.primarycancerconditionidentifier
               WHERE ip.procedureidentifier = s.imagingprocedureidentifier
                 AND pcc.patientidentifier  = s.patientidentifier))   AS linked,
       CASE WHEN COUNT(*) = COUNT(*) FILTER (WHERE EXISTS (
               SELECT 1
               FROM eucaim_cdm_ingestion.imagingprocedure ip
               JOIN eucaim_cdm_ingestion.primarycancercondition pcc
                 ON pcc.identifier = ip.primarycancerconditionidentifier
               WHERE ip.procedureidentifier = s.imagingprocedureidentifier
                 AND pcc.patientidentifier  = s.patientidentifier))
            THEN 'PASS' ELSE 'FAIL' END                           AS all_linked
FROM eucaim_cdm_ingestion.imagestudy s
WHERE :dataset IS NULL OR s.datasetidentifier = :dataset
GROUP BY s.datasetidentifier
ORDER BY s.datasetidentifier;


-- 2. Why the unlinked studies are unlinked. Each study falls in the first cause that applies.
SELECT s.datasetidentifier AS dataset_id,
       CASE
         WHEN s.imagingtimepoint IS NULL
           THEN 'no timepoint: the timepoints csv never reached the study (its StudyInstanceUID or PatientID differ from the DICOM metadata, or a column is missing)'
         WHEN s.imagingtimepoint = 0
           THEN 'timepoint 0: the Timepoint column was not found under that name'
         WHEN NOT EXISTS (
                SELECT 1
                FROM eucaim_cdm_ingestion.imagingprocedure ip
                JOIN eucaim_cdm_ingestion.primarycancercondition pcc
                  ON pcc.identifier = ip.primarycancerconditionidentifier
                WHERE pcc.patientidentifier = s.patientidentifier)
           THEN 'the patient of the study has no imaging procedure in the clinical data'
         WHEN NOT EXISTS (
                SELECT 1
                FROM eucaim_cdm_ingestion.imagingprocedure ip
                JOIN eucaim_cdm_ingestion.primarycancercondition pcc
                  ON pcc.identifier = ip.primarycancerconditionidentifier
                WHERE pcc.patientidentifier = s.patientidentifier
                  AND ip.imagingtimepoint   = s.imagingtimepoint)
           THEN 'the timepoint is higher than the number of exams the patient has in the clinical data'
         ELSE 'timepoint and procedure exist but the study is not linked (the timepoints csv was not ingested after the clinical data)'
       END AS cause,
       COUNT(*) AS studies
FROM eucaim_cdm_ingestion.imagestudy s
WHERE (:dataset IS NULL OR s.datasetidentifier = :dataset)
  AND NOT EXISTS (
        SELECT 1
        FROM eucaim_cdm_ingestion.imagingprocedure ip
        JOIN eucaim_cdm_ingestion.primarycancercondition pcc
          ON pcc.identifier = ip.primarycancerconditionidentifier
        WHERE ip.procedureidentifier = s.imagingprocedureidentifier
          AND pcc.patientidentifier  = s.patientidentifier)
GROUP BY 1, 2
ORDER BY 1, 3 DESC;


-- 3. Studies and imaging procedures per timepoint number: a procedure with no study, or a timepoint
--    with studies and no procedures, shows where the two files stop agreeing.
WITH st AS (
    SELECT datasetidentifier AS dataset_id, imagingtimepoint AS timepoint, COUNT(*) AS studies
    FROM eucaim_cdm_ingestion.imagestudy
    WHERE :dataset IS NULL OR datasetidentifier = :dataset
    GROUP BY 1, 2
), pr AS (
    SELECT cp.datasetidentifier AS dataset_id, ip.imagingtimepoint AS timepoint, COUNT(*) AS procedures
    FROM eucaim_cdm_ingestion.imagingprocedure ip
    JOIN eucaim_cdm_ingestion.primarycancercondition pcc ON pcc.identifier = ip.primarycancerconditionidentifier
    JOIN eucaim_cdm_ingestion.cancerpatient cp           ON cp.identifier  = pcc.patientidentifier
    WHERE :dataset IS NULL OR cp.datasetidentifier = :dataset
    GROUP BY 1, 2
)
SELECT COALESCE(st.dataset_id, pr.dataset_id) AS dataset_id,
       COALESCE(st.timepoint, pr.timepoint)   AS timepoint,
       COALESCE(st.studies, 0)                AS studies,
       COALESCE(pr.procedures, 0)             AS imaging_procedures
FROM st
FULL JOIN pr ON pr.dataset_id = st.dataset_id AND pr.timepoint IS NOT DISTINCT FROM st.timepoint
ORDER BY 1, 2 NULLS FIRST;


-- 4. Only with -v list_uids=1: the unlinked study UIDs, to compare by hand with the timepoints csv.
--    Identifiers: do not forward this output.
\if :{?list_uids}
SELECT s.datasetidentifier AS dataset_id, s.imagestudyuid, s.imagingtimepoint
FROM eucaim_cdm_ingestion.imagestudy s
WHERE (:dataset IS NULL OR s.datasetidentifier = :dataset)
  AND s.imagingprocedureidentifier IS NULL
ORDER BY 1, 2;
\endif
