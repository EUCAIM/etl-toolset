-- Generic checks for eucaim_cdm_ingestion schema 

\if :{?dataset}
\else
  \set dataset NULL
\endif


-- 1. Global checks, one row each
SELECT
    (SELECT COUNT(*) FROM eucaim_cdm_ingestion.dataset)       AS datasets,
    (SELECT COUNT(*) FROM eucaim_cdm_ingestion.cancerpatient) AS patients,
    (SELECT COUNT(*) FROM eucaim_cdm_ingestion.cancerrelatedprocedure)
      + (SELECT COUNT(*) FROM eucaim_cdm_ingestion.imagingprocedure) AS procedures,
    (SELECT COUNT(*) FROM eucaim_cdm_ingestion.imagestudy)    AS studies,
    (SELECT COUNT(*) FROM eucaim_cdm_ingestion.imageseries)   AS series,
    CASE WHEN (SELECT COUNT(*) FROM eucaim_cdm_ingestion.cancerpatient) > 0
         THEN 'PASS' ELSE 'FAIL' END AS clinical_data,
    CASE WHEN (SELECT COUNT(*) FROM eucaim_cdm_ingestion.imageseries) > 0
         THEN 'PASS' ELSE 'FAIL' END AS imaging_metadata;


-- 2. Breakdown per dataset
--    absent (or smaller) there means loop03 hasn't caught up with it yet.
WITH patients AS (
    SELECT datasetidentifier AS dataset_id, COUNT(*) AS patients
    FROM eucaim_cdm_ingestion.cancerpatient
    GROUP BY datasetidentifier
), primary_cancer_conditions AS (
    SELECT cp.datasetidentifier AS dataset_id, COUNT(*) AS primary_cancer_conditions
    FROM eucaim_cdm_ingestion.primarycancercondition pcc
    JOIN eucaim_cdm_ingestion.cancerpatient cp ON cp.identifier = pcc.patientidentifier
    GROUP BY cp.datasetidentifier
), cancer_related_procedures AS (
    SELECT cp.datasetidentifier AS dataset_id, COUNT(*) AS cancer_related_procedures
    FROM eucaim_cdm_ingestion.cancerrelatedprocedure crp
    JOIN eucaim_cdm_ingestion.primarycancercondition pcc ON pcc.identifier = crp.primarycancerconditionidentifier
    JOIN eucaim_cdm_ingestion.cancerpatient cp           ON cp.identifier = pcc.patientidentifier
    GROUP BY cp.datasetidentifier
), imaging_procedures AS (
    SELECT cp.datasetidentifier AS dataset_id, COUNT(*) AS imaging_procedures
    FROM eucaim_cdm_ingestion.imagingprocedure ip
    JOIN eucaim_cdm_ingestion.cancerpatient cp ON cp.identifier = ip.patientidentifier
    GROUP BY cp.datasetidentifier
), treatments AS (
    SELECT cp.datasetidentifier AS dataset_id, COUNT(*) AS treatments
    FROM (
        SELECT patientidentifier FROM eucaim_cdm_ingestion.radiotherapycoursesummary
        UNION ALL
        SELECT patientidentifier FROM eucaim_cdm_ingestion.surgicalprocedure
        UNION ALL
        SELECT patientidentifier FROM eucaim_cdm_ingestion.cancerrelatedmedication
    ) tr
    JOIN eucaim_cdm_ingestion.cancerpatient cp ON cp.identifier = tr.patientidentifier
    GROUP BY cp.datasetidentifier
), studies AS (
    SELECT datasetidentifier AS dataset_id, COUNT(*) AS studies
    FROM eucaim_cdm_ingestion.imagestudy
    GROUP BY datasetidentifier
), series AS (
    SELECT st.datasetidentifier AS dataset_id, COUNT(*) AS series
    FROM eucaim_cdm_ingestion.imageseries se
    JOIN eucaim_cdm_ingestion.imagestudy st ON st.imagestudyuid = se.imagestudyuid
    GROUP BY st.datasetidentifier
), image_tags AS (
    SELECT st.datasetidentifier AS dataset_id, COUNT(*) AS image_tags
    FROM eucaim_cdm_ingestion.imagetags it
    JOIN eucaim_cdm_ingestion.imagestudy st ON st.imagestudyuid = it.imagestudyuid
    GROUP BY st.datasetidentifier
)
SELECT
    d.identifier AS dataset_id,
    d.title      AS dataset_title,
    COALESCE(patients.patients, 0)                                       AS patients,
    COALESCE(primary_cancer_conditions.primary_cancer_conditions, 0)     AS primary_cancer_conditions,
    COALESCE(cancer_related_procedures.cancer_related_procedures, 0)     AS cancer_related_procedures,
    COALESCE(imaging_procedures.imaging_procedures, 0)                   AS imaging_procedures,
    COALESCE(treatments.treatments, 0)                                   AS treatments,
    COALESCE(studies.studies, 0)                                         AS studies,
    COALESCE(series.series, 0)                                           AS series,
    COALESCE(image_tags.image_tags, 0)                                   AS image_tags
FROM eucaim_cdm_ingestion.dataset d
LEFT JOIN patients                    ON patients.dataset_id = d.identifier
LEFT JOIN primary_cancer_conditions   ON primary_cancer_conditions.dataset_id = d.identifier
LEFT JOIN cancer_related_procedures   ON cancer_related_procedures.dataset_id = d.identifier
LEFT JOIN imaging_procedures          ON imaging_procedures.dataset_id = d.identifier
LEFT JOIN treatments                  ON treatments.dataset_id = d.identifier
LEFT JOIN studies                     ON studies.dataset_id = d.identifier
LEFT JOIN series                      ON series.dataset_id = d.identifier
LEFT JOIN image_tags                  ON image_tags.dataset_id = d.identifier
WHERE :dataset IS NULL OR d.identifier = :dataset
ORDER BY d.identifier;


-- 3. Clinical & imaging data
SELECT * FROM (
    SELECT 'cancerpatient.birthsexeucaim' AS field, COUNT(*) AS rows,
           COUNT(cp.birthsexeucaim) AS filled
    FROM eucaim_cdm_ingestion.cancerpatient cp
    WHERE :dataset IS NULL OR cp.datasetidentifier = :dataset
    UNION ALL
    SELECT 'cancerpatient.diagnosticcategoryeucaim', COUNT(*),
           COUNT(cp.diagnosticcategoryeucaim)
    FROM eucaim_cdm_ingestion.cancerpatient cp
    WHERE :dataset IS NULL OR cp.datasetidentifier = :dataset
    UNION ALL
    SELECT 'primarycancercondition.primarycancerconditioneucaim', COUNT(*),
           COUNT(pcc.primarycancerconditioneucaim)
    FROM eucaim_cdm_ingestion.primarycancercondition pcc
    JOIN eucaim_cdm_ingestion.cancerpatient cp ON cp.identifier = pcc.patientidentifier
    WHERE :dataset IS NULL OR cp.datasetidentifier = :dataset
    UNION ALL
    SELECT 'cancerrelatedprocedure.procedureeucaim', COUNT(*),
           COUNT(crp.procedureeucaim)
    FROM eucaim_cdm_ingestion.cancerrelatedprocedure crp
    JOIN eucaim_cdm_ingestion.primarycancercondition pcc ON pcc.identifier = crp.primarycancerconditionidentifier
    JOIN eucaim_cdm_ingestion.cancerpatient cp           ON cp.identifier = pcc.patientidentifier
    WHERE :dataset IS NULL OR cp.datasetidentifier = :dataset
    UNION ALL
    SELECT 'imagingprocedure.imagingprocedureeucaim', COUNT(*),
           COUNT(ip.imagingprocedureeucaim)
    FROM eucaim_cdm_ingestion.imagingprocedure ip
    JOIN eucaim_cdm_ingestion.cancerpatient cp ON cp.identifier = ip.patientidentifier
    WHERE :dataset IS NULL OR cp.datasetidentifier = :dataset
    UNION ALL
    SELECT 'imageseries.modality', COUNT(*), COUNT(se.modality)
    FROM eucaim_cdm_ingestion.imageseries se
    JOIN eucaim_cdm_ingestion.imagestudy st ON st.imagestudyuid = se.imagestudyuid
    WHERE :dataset IS NULL OR st.datasetidentifier = :dataset
) f
ORDER BY field;


-- 4. Imaging metadata: volume and spread across modalities.
SELECT
    COALESCE(se.modality, '(null)') AS modality,
    COUNT(DISTINCT se.imagestudyuid) AS studies,
    COUNT(*)                         AS series,
    COUNT(DISTINCT se.bodypart)      AS distinct_body_parts
FROM eucaim_cdm_ingestion.imageseries se
JOIN eucaim_cdm_ingestion.imagestudy st ON st.imagestudyuid = se.imagestudyuid
WHERE :dataset IS NULL OR st.datasetidentifier = :dataset
GROUP BY se.modality
ORDER BY series DESC;


-- 5. Referential integrity
SELECT 'patients without dataset' AS check_name, COUNT(*) AS offenders
FROM eucaim_cdm_ingestion.cancerpatient
WHERE datasetidentifier IS NULL
UNION ALL
SELECT 'primary cancer conditions without patient', COUNT(*)
FROM eucaim_cdm_ingestion.primarycancercondition pcc
WHERE NOT EXISTS (SELECT 1 FROM eucaim_cdm_ingestion.cancerpatient cp
                  WHERE cp.identifier = pcc.patientidentifier)
UNION ALL
SELECT 'cancer related procedures without primary cancer condition', COUNT(*)
FROM eucaim_cdm_ingestion.cancerrelatedprocedure crp
WHERE NOT EXISTS (SELECT 1 FROM eucaim_cdm_ingestion.primarycancercondition pcc
                  WHERE pcc.identifier = crp.primarycancerconditionidentifier)
UNION ALL
SELECT 'imaging procedures without patient', COUNT(*)
FROM eucaim_cdm_ingestion.imagingprocedure ip
WHERE NOT EXISTS (SELECT 1 FROM eucaim_cdm_ingestion.cancerpatient cp
                  WHERE cp.identifier = ip.patientidentifier)
UNION ALL
SELECT 'tumors without primary cancer condition', COUNT(*)
FROM eucaim_cdm_ingestion.tumor t
WHERE NOT EXISTS (SELECT 1 FROM eucaim_cdm_ingestion.primarycancercondition pcc
                  WHERE pcc.identifier = t.primarycancerconditionidentifier)
UNION ALL
SELECT 'studies without patient', COUNT(*)
FROM eucaim_cdm_ingestion.imagestudy
WHERE patientidentifier IS NULL
UNION ALL
SELECT 'studies without any series', COUNT(*)
FROM eucaim_cdm_ingestion.imagestudy st
WHERE (:dataset IS NULL OR st.datasetidentifier = :dataset)
  AND NOT EXISTS (SELECT 1 FROM eucaim_cdm_ingestion.imageseries se
                  WHERE se.imagestudyuid = st.imagestudyuid)
UNION ALL
SELECT 'series with dangling study_uid', COUNT(*)
FROM eucaim_cdm_ingestion.imageseries se
WHERE NOT EXISTS (SELECT 1 FROM eucaim_cdm_ingestion.imagestudy st
                  WHERE st.imagestudyuid = se.imagestudyuid)
UNION ALL
SELECT 'orphan image tags', COUNT(*)
FROM eucaim_cdm_ingestion.imagetags it
WHERE NOT EXISTS (SELECT 1 FROM eucaim_cdm_ingestion.imageseries se
                  WHERE se.imageseriesuid = it.imageseriesuid);


-- 6. Clinical <-> imaging crossover
SELECT
    d.identifier AS dataset_id,
    COUNT(*) FILTER (WHERE st.has_study IS NOT NULL) AS patients_with_imaging,
    COUNT(*) FILTER (WHERE st.has_study IS NULL)     AS patients_clinical_only
FROM eucaim_cdm_ingestion.dataset d
JOIN eucaim_cdm_ingestion.cancerpatient p ON p.datasetidentifier = d.identifier
LEFT JOIN LATERAL (
    SELECT 1 AS has_study FROM eucaim_cdm_ingestion.imagestudy s
    WHERE s.patientidentifier = p.identifier LIMIT 1
) st ON true
WHERE :dataset IS NULL OR d.identifier = :dataset
GROUP BY d.identifier
ORDER BY d.identifier;
