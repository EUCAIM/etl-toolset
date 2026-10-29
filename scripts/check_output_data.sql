
-- Usage:
--   docker exec -i $(docker compose ps -q nifi-postgres) \
--     psql -U postgres -d eucaim-etl-db -f - < scripts/check_output_data.sql
-- or, to scope to a single dataset:
--   ... psql -U postgres -d eucaim-etl-db -v dataset="'<dataset_id>'" -f ...
-- (:dataset defaults to NULL, which makes every check span all datasets)

\if :{?dataset}
\else
  \set dataset NULL
\endif


-- 1. Global checks, one row each
SELECT
    (SELECT COUNT(*) FROM eucaim_cdm_output.dataset)     AS datasets,
    (SELECT COUNT(*) FROM eucaim_cdm_output.patient)     AS patients,
    (SELECT COUNT(*) FROM eucaim_cdm_output.procedure)   AS procedures,
    (SELECT COUNT(*) FROM eucaim_cdm_output.image_study) AS studies,
    (SELECT COUNT(*) FROM eucaim_cdm_output.image_series) AS series,
    CASE WHEN (SELECT COUNT(*) FROM eucaim_cdm_output.patient) > 0
         THEN 'PASS' ELSE 'FAIL' END AS clinical_data,
    CASE WHEN (SELECT COUNT(*) FROM eucaim_cdm_output.image_series) > 0
         THEN 'PASS' ELSE 'FAIL' END AS imaging_metadata;


-- 2. Breakdown per dataset
WITH patients AS (
    SELECT dataset_id, COUNT(*) AS patients
    FROM eucaim_cdm_output.patient
    GROUP BY dataset_id
), procedures AS (
    SELECT p.dataset_id, COUNT(*) AS procedures
    FROM eucaim_cdm_output.procedure pr
    JOIN eucaim_cdm_output.patient p ON p.patient_id = pr.patient_id
    GROUP BY p.dataset_id
), cancer_conditions AS (
    SELECT p.dataset_id, COUNT(*) AS cancer_conditions
    FROM eucaim_cdm_output.cancer_condition cc
    JOIN eucaim_cdm_output.patient p ON p.patient_id = cc.patient_id
    GROUP BY p.dataset_id
), treatments AS (
    SELECT p.dataset_id, COUNT(*) AS treatments
    FROM eucaim_cdm_output.treatment t
    JOIN eucaim_cdm_output.patient p ON p.patient_id = t.patient_id
    GROUP BY p.dataset_id
), studies AS (
    SELECT p.dataset_id, COUNT(*) AS studies
    FROM eucaim_cdm_output.image_study st
    JOIN eucaim_cdm_output.patient p ON p.patient_id = st.patient_id
    GROUP BY p.dataset_id
), series AS (
    SELECT p.dataset_id, COUNT(*) AS series
    FROM eucaim_cdm_output.image_series se
    JOIN eucaim_cdm_output.image_study st ON st.study_uid = se.study_uid
    JOIN eucaim_cdm_output.patient p     ON p.patient_id = st.patient_id
    GROUP BY p.dataset_id
), acquisition_params AS (
    SELECT p.dataset_id, COUNT(*) AS acquisition_params
    FROM eucaim_cdm_output.image_modality im
    JOIN eucaim_cdm_output.image_series se ON se.series_uid = im.series_uid
    JOIN eucaim_cdm_output.image_study st  ON st.study_uid = se.study_uid
    JOIN eucaim_cdm_output.patient p       ON p.patient_id = st.patient_id
    GROUP BY p.dataset_id
)
SELECT
    d.dataset_id,
    d.dataset_title,
    COALESCE(patients.patients, 0)                     AS patients,
    COALESCE(procedures.procedures, 0)                 AS procedures,
    COALESCE(cancer_conditions.cancer_conditions, 0)   AS cancer_conditions,
    COALESCE(treatments.treatments, 0)                 AS treatments,
    COALESCE(studies.studies, 0)                       AS studies,
    COALESCE(series.series, 0)                         AS series,
    COALESCE(acquisition_params.acquisition_params, 0) AS acquisition_params
FROM eucaim_cdm_output.dataset d
LEFT JOIN patients            ON patients.dataset_id = d.dataset_id
LEFT JOIN procedures          ON procedures.dataset_id = d.dataset_id
LEFT JOIN cancer_conditions   ON cancer_conditions.dataset_id = d.dataset_id
LEFT JOIN treatments          ON treatments.dataset_id = d.dataset_id
LEFT JOIN studies             ON studies.dataset_id = d.dataset_id
LEFT JOIN series              ON series.dataset_id = d.dataset_id
LEFT JOIN acquisition_params  ON acquisition_params.dataset_id = d.dataset_id
WHERE :dataset IS NULL OR d.dataset_id = :dataset
ORDER BY d.dataset_id;


-- 3. Clinical & imaging data
SELECT * FROM (
    SELECT 'patient.patient_birth_sex' AS field, COUNT(*) AS rows,
           COUNT(p.patient_birth_sex) AS filled
    FROM eucaim_cdm_output.patient p
    WHERE :dataset IS NULL OR p.dataset_id = :dataset
    UNION ALL
    SELECT 'patient.patient_diagnostic_category', COUNT(*),
           COUNT(p.patient_diagnostic_category)
    FROM eucaim_cdm_output.patient p
    WHERE :dataset IS NULL OR p.dataset_id = :dataset
    UNION ALL
    SELECT 'cancer_condition.cancer_condition_code', COUNT(*),
           COUNT(cc.cancer_condition_code)
    FROM eucaim_cdm_output.cancer_condition cc
    JOIN eucaim_cdm_output.patient p ON p.patient_id = cc.patient_id
    WHERE :dataset IS NULL OR p.dataset_id = :dataset
    UNION ALL
    SELECT 'procedure.procedure_code', COUNT(*), COUNT(pr.procedure_code)
    FROM eucaim_cdm_output.procedure pr
    JOIN eucaim_cdm_output.patient p ON p.patient_id = pr.patient_id
    WHERE :dataset IS NULL OR p.dataset_id = :dataset
    UNION ALL
    SELECT 'treatment.treatment_type', COUNT(*), COUNT(t.treatment_type)
    FROM eucaim_cdm_output.treatment t
    JOIN eucaim_cdm_output.patient p ON p.patient_id = t.patient_id
    WHERE :dataset IS NULL OR p.dataset_id = :dataset
    UNION ALL
    SELECT 'image_study.study_acquisition_date', COUNT(*), COUNT(st.study_acquisition_date)
    FROM eucaim_cdm_output.image_study st
    JOIN eucaim_cdm_output.patient p ON p.patient_id = st.patient_id
    WHERE :dataset IS NULL OR p.dataset_id = :dataset
    UNION ALL
    SELECT 'image_series.series_modality', COUNT(*), COUNT(se.series_modality)
    FROM eucaim_cdm_output.image_series se
    JOIN eucaim_cdm_output.image_study st ON st.study_uid = se.study_uid
    JOIN eucaim_cdm_output.patient p      ON p.patient_id = st.patient_id
    WHERE :dataset IS NULL OR p.dataset_id = :dataset
) f
ORDER BY field;


-- 4. Imaging metadata: volume and spread across modalities.
SELECT
    COALESCE(se.series_modality, '(null)') AS modality,
    COUNT(DISTINCT se.study_uid)  AS studies,
    COUNT(*)                      AS series,
    COUNT(DISTINCT se.series_body_site) AS distinct_body_sites
FROM eucaim_cdm_output.image_series se
JOIN eucaim_cdm_output.image_study st ON st.study_uid = se.study_uid
JOIN eucaim_cdm_output.patient p      ON p.patient_id = st.patient_id
WHERE :dataset IS NULL OR p.dataset_id = :dataset
GROUP BY se.series_modality
ORDER BY series DESC;


-- 5. Referential integrity of the imaging side
SELECT 'studies without patient'          AS check_name, COUNT(*) AS offenders
FROM eucaim_cdm_output.image_study WHERE patient_id IS NULL
UNION ALL
SELECT 'studies without any series', COUNT(*)
FROM eucaim_cdm_output.image_study st
JOIN eucaim_cdm_output.patient p ON p.patient_id = st.patient_id
WHERE (:dataset IS NULL OR p.dataset_id = :dataset)
  AND NOT EXISTS (SELECT 1 FROM eucaim_cdm_output.image_series se
                  WHERE se.study_uid = st.study_uid)
UNION ALL
-- desde que study_uid/series_uid son la clave y la FK, estas dos ya no pueden
-- fallar; se mantienen porque documentan la invariante (global, no admite :dataset)
SELECT 'series with dangling study_uid', COUNT(*)
FROM eucaim_cdm_output.image_series se
WHERE NOT EXISTS (SELECT 1 FROM eucaim_cdm_output.image_study st
                  WHERE st.study_uid = se.study_uid)
UNION ALL
SELECT 'orphan acquisition params', COUNT(*)
FROM eucaim_cdm_output.image_modality im
WHERE NOT EXISTS (SELECT 1 FROM eucaim_cdm_output.image_series se
                  WHERE se.series_uid = im.series_uid)
UNION ALL
SELECT 'patients without dataset', COUNT(*)
FROM eucaim_cdm_output.patient WHERE dataset_id IS NULL;


-- 6. Clinical <-> imaging crossover: how many patients have both halves.
SELECT
    d.dataset_id,
    COUNT(*) FILTER (WHERE st.has_study IS NOT NULL) AS patients_with_imaging,
    COUNT(*) FILTER (WHERE st.has_study IS NULL)     AS patients_clinical_only
FROM eucaim_cdm_output.dataset d
JOIN eucaim_cdm_output.patient p ON p.dataset_id = d.dataset_id
LEFT JOIN LATERAL (
    SELECT 1 AS has_study FROM eucaim_cdm_output.image_study s
    WHERE s.patient_id = p.patient_id LIMIT 1
) st ON true
WHERE :dataset IS NULL OR d.dataset_id = :dataset
GROUP BY d.dataset_id
ORDER BY d.dataset_id;
