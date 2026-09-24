-- Compares eucaim_cdm_ingestion against eucaim_cdm_output, dataset by
-- dataset and entity by entity, to spot where loop03 (ingestion -> output)
-- has fallen behind

\if :{?dataset}
\else
  \set dataset NULL
\endif


-- 1. Datasets known to ingestion but absent from output
SELECT
    di.identifier AS dataset_id,
    di.title      AS dataset_title,
    di.processed  AS ingestion_marked_processed
FROM eucaim_cdm_ingestion.dataset di
WHERE (:dataset IS NULL OR di.identifier = :dataset)
  AND NOT EXISTS (SELECT 1 FROM eucaim_cdm_output.dataset do_
                  WHERE do_.dataset_id = di.identifier)
ORDER BY di.identifier;


-- 2. Side-by-side entity counts for datasets present on both sides
WITH ingestion_patients AS (
    SELECT datasetidentifier AS dataset_id, COUNT(*) AS patients
    FROM eucaim_cdm_ingestion.cancerpatient
    GROUP BY datasetidentifier
), output_patients AS (
    SELECT dataset_id, COUNT(*) AS patients
    FROM eucaim_cdm_output.patient
    GROUP BY dataset_id
), ingestion_procedures AS (
    SELECT cp.datasetidentifier AS dataset_id, COUNT(*) AS procedures
    FROM (
        SELECT patientidentifier FROM eucaim_cdm_ingestion.cancerrelatedprocedure crp
        JOIN eucaim_cdm_ingestion.primarycancercondition pcc ON pcc.identifier = crp.primarycancerconditionidentifier
        UNION ALL
        SELECT patientidentifier FROM eucaim_cdm_ingestion.imagingprocedure
    ) pr
    JOIN eucaim_cdm_ingestion.cancerpatient cp ON cp.identifier = pr.patientidentifier
    GROUP BY cp.datasetidentifier
), output_procedures AS (
    SELECT p.dataset_id, COUNT(*) AS procedures
    FROM eucaim_cdm_output.procedure pr
    JOIN eucaim_cdm_output.patient p ON p.patient_id = pr.patient_id
    GROUP BY p.dataset_id
), ingestion_studies AS (
    SELECT datasetidentifier AS dataset_id, COUNT(*) AS studies
    FROM eucaim_cdm_ingestion.imagestudy
    GROUP BY datasetidentifier
), output_studies AS (
    SELECT p.dataset_id, COUNT(*) AS studies
    FROM eucaim_cdm_output.image_study st
    JOIN eucaim_cdm_output.patient p ON p.patient_id = st.patient_id
    GROUP BY p.dataset_id
), ingestion_series AS (
    SELECT st.datasetidentifier AS dataset_id, COUNT(*) AS series
    FROM eucaim_cdm_ingestion.imageseries se
    JOIN eucaim_cdm_ingestion.imagestudy st ON st.imagestudyuid = se.imagestudyuid
    GROUP BY st.datasetidentifier
), output_series AS (
    SELECT p.dataset_id, COUNT(*) AS series
    FROM eucaim_cdm_output.image_series se
    JOIN eucaim_cdm_output.image_study st ON st.study_uid = se.study_uid
    JOIN eucaim_cdm_output.patient p     ON p.patient_id = st.patient_id
    GROUP BY p.dataset_id
)
SELECT
    di.identifier AS dataset_id,
    di.title      AS dataset_title,
    COALESCE(ingestion_patients.patients, 0)     AS ing_patients,
    COALESCE(output_patients.patients, 0)        AS out_patients,
    COALESCE(ingestion_procedures.procedures, 0) AS ing_procedures,
    COALESCE(output_procedures.procedures, 0)    AS out_procedures,
    COALESCE(ingestion_studies.studies, 0)       AS ing_studies,
    COALESCE(output_studies.studies, 0)          AS out_studies,
    COALESCE(ingestion_series.series, 0)         AS ing_series,
    COALESCE(output_series.series, 0)            AS out_series
FROM eucaim_cdm_ingestion.dataset di
LEFT JOIN ingestion_patients   ON ingestion_patients.dataset_id = di.identifier
LEFT JOIN output_patients      ON output_patients.dataset_id = di.identifier
LEFT JOIN ingestion_procedures ON ingestion_procedures.dataset_id = di.identifier
LEFT JOIN output_procedures    ON output_procedures.dataset_id = di.identifier
LEFT JOIN ingestion_studies    ON ingestion_studies.dataset_id = di.identifier
LEFT JOIN output_studies       ON output_studies.dataset_id = di.identifier
LEFT JOIN ingestion_series     ON ingestion_series.dataset_id = di.identifier
LEFT JOIN output_series        ON output_series.dataset_id = di.identifier
WHERE :dataset IS NULL OR di.identifier = :dataset
ORDER BY di.identifier;


-- 3. Patients present in ingestion (and marked processed) with no matching
--    patient in output
SELECT
    cp.datasetidentifier AS dataset_id,
    COUNT(*) AS ingestion_processed_patients_missing_in_output
FROM eucaim_cdm_ingestion.cancerpatient cp
WHERE cp.processed
  AND (:dataset IS NULL OR cp.datasetidentifier = :dataset)
  AND NOT EXISTS (SELECT 1 FROM eucaim_cdm_output.patient p
                  WHERE p.patient_id = cp.identifier)
GROUP BY cp.datasetidentifier
ORDER BY cp.datasetidentifier;
