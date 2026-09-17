-- Generic checks for eucaim_cdm_output schema (implementation of EUCAIM CDM).
-- They answer "do we have clinical data and imaging metadata ingested?",
-- without depending on any particular dataset or patient.
--
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


-- 1. Global traffic light: one row, PASS/FAIL per block.
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


-- 2. Breakdown per dataset: volume of each main entity.
--    A 0 under patients means loop03 never wrote anything; a 0 only under
--    studies/series points at a missing DICOM half.
SELECT
    d.dataset_id,
    d.dataset_title,
    COUNT(DISTINCT p.patient_id)   AS patients,
    COUNT(DISTINCT pr.procedure_id) AS procedures,
    COUNT(DISTINCT cc.cancer_condition_id) AS cancer_conditions,
    COUNT(DISTINCT t.treatment_id) AS treatments,
    COUNT(DISTINCT st.study_id)    AS studies,
    COUNT(DISTINCT se.series_id)   AS series,
    COUNT(DISTINCT im.modality_id) AS acquisition_params
FROM eucaim_cdm_output.dataset d
LEFT JOIN eucaim_cdm_output.patient p           ON p.dataset_id = d.dataset_id
LEFT JOIN eucaim_cdm_output.procedure pr        ON pr.patient_id = p.patient_id
LEFT JOIN eucaim_cdm_output.cancer_condition cc ON cc.patient_id = p.patient_id
LEFT JOIN eucaim_cdm_output.treatment t         ON t.patient_id = p.patient_id
LEFT JOIN eucaim_cdm_output.image_study st      ON st.patient_id = p.patient_id
LEFT JOIN eucaim_cdm_output.image_series se     ON se.study_id = st.study_id
LEFT JOIN eucaim_cdm_output.image_modality im   ON im.series_id = se.series_id
WHERE :dataset IS NULL OR d.dataset_id = :dataset
GROUP BY d.dataset_id, d.dataset_title
ORDER BY d.dataset_id;


-- 3. Clinical data: fill rate of the fields that should never come back all NULL.
--    filled = 0 over rows > 0 is the usual symptom of a broken mapping or lookup.
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
) f
ORDER BY field;


-- 4. Imaging metadata: volume and spread across modalities.
SELECT
    COALESCE(se.series_modality, '(null)') AS modality,
    COUNT(DISTINCT se.study_uid)  AS studies,
    COUNT(*)                      AS series,
    COUNT(DISTINCT se.series_body_site) AS distinct_body_sites
FROM eucaim_cdm_output.image_series se
JOIN eucaim_cdm_output.image_study st ON st.study_id = se.study_id
JOIN eucaim_cdm_output.patient p      ON p.patient_id = st.patient_id
WHERE :dataset IS NULL OR p.dataset_id = :dataset
GROUP BY se.series_modality
ORDER BY series DESC;


-- 5. Referential integrity of the imaging side: every row here must be 0.
SELECT 'studies without patient'          AS check_name, COUNT(*) AS offenders
FROM eucaim_cdm_output.image_study WHERE patient_id IS NULL
UNION ALL
SELECT 'studies without any series', COUNT(*)
FROM eucaim_cdm_output.image_study st
WHERE NOT EXISTS (SELECT 1 FROM eucaim_cdm_output.image_series se
                  WHERE se.study_id = st.study_id)
UNION ALL
SELECT 'orphan series (study_id NULL)', COUNT(*)
FROM eucaim_cdm_output.image_series WHERE study_id IS NULL
UNION ALL
SELECT 'series with dangling study_uid', COUNT(*)
FROM eucaim_cdm_output.image_series se
WHERE NOT EXISTS (SELECT 1 FROM eucaim_cdm_output.image_study st
                  WHERE st.study_uid = se.study_uid)
UNION ALL
SELECT 'orphan acquisition params', COUNT(*)
FROM eucaim_cdm_output.image_modality WHERE series_id IS NULL
UNION ALL
SELECT 'patients without dataset', COUNT(*)
FROM eucaim_cdm_output.patient WHERE dataset_id IS NULL;


-- 6. Clinical <-> imaging crossover: how many patients have both halves.
SELECT
    d.dataset_id,
    COUNT(*) FILTER (WHERE st.study_id IS NOT NULL) AS patients_with_imaging,
    COUNT(*) FILTER (WHERE st.study_id IS NULL)     AS patients_clinical_only
FROM eucaim_cdm_output.dataset d
JOIN eucaim_cdm_output.patient p ON p.dataset_id = d.dataset_id
LEFT JOIN LATERAL (
    SELECT 1 AS study_id FROM eucaim_cdm_output.image_study s
    WHERE s.patient_id = p.patient_id LIMIT 1
) st ON true
WHERE :dataset IS NULL OR d.dataset_id = :dataset
GROUP BY d.dataset_id
ORDER BY d.dataset_id;
