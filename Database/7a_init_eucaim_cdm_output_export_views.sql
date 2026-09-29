-- Step 7a Eucaim CDM Schema: export views
--
-- One view per table of eucaim_cdm_output, and nothing else in this schema may
-- be named v_export_*: eucaim_etl_aux.export_dataset_to_csv_v001 discovers what
-- to export by listing exactly this prefix in information_schema.views, so
-- adding a table to the CDM means adding a view here and changing no code, in
-- the database or in NiFi.
--
-- Each view is the table as it stands, in its own column order, plus one extra
-- last column, export_dataset_id, which is the dataset the row belongs to. The
-- export procedure drops that column from the CSV by name, so the header of
-- every exported file is the CDM table's own column list and nothing else. The
-- column is not called dataset_id because dataset and patient already have a
-- CDM column with that name, and the procedure would then strip a real one.
--
-- A row whose export_dataset_id resolves to NULL (an orphan body_site, a
-- segmentation whose study never arrived) matches no dataset and is exported
-- nowhere. That is deliberate: the bundle of a dataset must contain only rows
-- reachable from that dataset.

DROP VIEW IF EXISTS eucaim_cdm_output.v_export_dataset CASCADE;
CREATE VIEW eucaim_cdm_output.v_export_dataset AS
SELECT t.*, t.dataset_id AS export_dataset_id
FROM eucaim_cdm_output.dataset t;

DROP VIEW IF EXISTS eucaim_cdm_output.v_export_patient CASCADE;
CREATE VIEW eucaim_cdm_output.v_export_patient AS
SELECT t.*, t.dataset_id AS export_dataset_id
FROM eucaim_cdm_output.patient t;

-- Rows that carry patient_id: the dataset is the one of their patient.

DROP VIEW IF EXISTS eucaim_cdm_output.v_export_procedure CASCADE;
CREATE VIEW eucaim_cdm_output.v_export_procedure AS
SELECT t.*, p.dataset_id AS export_dataset_id
FROM eucaim_cdm_output.procedure t
JOIN eucaim_cdm_output.patient p ON p.patient_id = t.patient_id;

DROP VIEW IF EXISTS eucaim_cdm_output.v_export_cancer_condition CASCADE;
CREATE VIEW eucaim_cdm_output.v_export_cancer_condition AS
SELECT t.*, p.dataset_id AS export_dataset_id
FROM eucaim_cdm_output.cancer_condition t
JOIN eucaim_cdm_output.patient p ON p.patient_id = t.patient_id;

DROP VIEW IF EXISTS eucaim_cdm_output.v_export_health_status_assessment CASCADE;
CREATE VIEW eucaim_cdm_output.v_export_health_status_assessment AS
SELECT t.*, p.dataset_id AS export_dataset_id
FROM eucaim_cdm_output.health_status_assessment t
JOIN eucaim_cdm_output.patient p ON p.patient_id = t.patient_id;

DROP VIEW IF EXISTS eucaim_cdm_output.v_export_tumor_marker_test CASCADE;
CREATE VIEW eucaim_cdm_output.v_export_tumor_marker_test AS
SELECT t.*, p.dataset_id AS export_dataset_id
FROM eucaim_cdm_output.tumor_marker_test t
JOIN eucaim_cdm_output.patient p ON p.patient_id = t.patient_id;

DROP VIEW IF EXISTS eucaim_cdm_output.v_export_family_member_history CASCADE;
CREATE VIEW eucaim_cdm_output.v_export_family_member_history AS
SELECT t.*, p.dataset_id AS export_dataset_id
FROM eucaim_cdm_output.family_member_history t
JOIN eucaim_cdm_output.patient p ON p.patient_id = t.patient_id;

DROP VIEW IF EXISTS eucaim_cdm_output.v_export_lab_test_result CASCADE;
CREATE VIEW eucaim_cdm_output.v_export_lab_test_result AS
SELECT t.*, p.dataset_id AS export_dataset_id
FROM eucaim_cdm_output.lab_test_result t
JOIN eucaim_cdm_output.patient p ON p.patient_id = t.patient_id;

DROP VIEW IF EXISTS eucaim_cdm_output.v_export_medical_history CASCADE;
CREATE VIEW eucaim_cdm_output.v_export_medical_history AS
SELECT t.*, p.dataset_id AS export_dataset_id
FROM eucaim_cdm_output.medical_history t
JOIN eucaim_cdm_output.patient p ON p.patient_id = t.patient_id;

DROP VIEW IF EXISTS eucaim_cdm_output.v_export_comorbidities CASCADE;
CREATE VIEW eucaim_cdm_output.v_export_comorbidities AS
SELECT t.*, p.dataset_id AS export_dataset_id
FROM eucaim_cdm_output.comorbidities t
JOIN eucaim_cdm_output.patient p ON p.patient_id = t.patient_id;

DROP VIEW IF EXISTS eucaim_cdm_output.v_export_histologic_grade CASCADE;
CREATE VIEW eucaim_cdm_output.v_export_histologic_grade AS
SELECT t.*, p.dataset_id AS export_dataset_id
FROM eucaim_cdm_output.histologic_grade t
JOIN eucaim_cdm_output.patient p ON p.patient_id = t.patient_id;

DROP VIEW IF EXISTS eucaim_cdm_output.v_export_cancer_stage CASCADE;
CREATE VIEW eucaim_cdm_output.v_export_cancer_stage AS
SELECT t.*, p.dataset_id AS export_dataset_id
FROM eucaim_cdm_output.cancer_stage t
JOIN eucaim_cdm_output.patient p ON p.patient_id = t.patient_id;

DROP VIEW IF EXISTS eucaim_cdm_output.v_export_tumor CASCADE;
CREATE VIEW eucaim_cdm_output.v_export_tumor AS
SELECT t.*, p.dataset_id AS export_dataset_id
FROM eucaim_cdm_output.tumor t
JOIN eucaim_cdm_output.patient p ON p.patient_id = t.patient_id;

DROP VIEW IF EXISTS eucaim_cdm_output.v_export_risk_assessment CASCADE;
CREATE VIEW eucaim_cdm_output.v_export_risk_assessment AS
SELECT t.*, p.dataset_id AS export_dataset_id
FROM eucaim_cdm_output.risk_assessment t
JOIN eucaim_cdm_output.patient p ON p.patient_id = t.patient_id;

DROP VIEW IF EXISTS eucaim_cdm_output.v_export_tumor_observation CASCADE;
CREATE VIEW eucaim_cdm_output.v_export_tumor_observation AS
SELECT t.*, p.dataset_id AS export_dataset_id
FROM eucaim_cdm_output.tumor_observation t
JOIN eucaim_cdm_output.patient p ON p.patient_id = t.patient_id;

DROP VIEW IF EXISTS eucaim_cdm_output.v_export_treatment CASCADE;
CREATE VIEW eucaim_cdm_output.v_export_treatment AS
SELECT t.*, p.dataset_id AS export_dataset_id
FROM eucaim_cdm_output.treatment t
JOIN eucaim_cdm_output.patient p ON p.patient_id = t.patient_id;

DROP VIEW IF EXISTS eucaim_cdm_output.v_export_radiotherapy CASCADE;
CREATE VIEW eucaim_cdm_output.v_export_radiotherapy AS
SELECT t.*, p.dataset_id AS export_dataset_id
FROM eucaim_cdm_output.radiotherapy t
JOIN eucaim_cdm_output.patient p ON p.patient_id = t.patient_id;

DROP VIEW IF EXISTS eucaim_cdm_output.v_export_surgical_procedure CASCADE;
CREATE VIEW eucaim_cdm_output.v_export_surgical_procedure AS
SELECT t.*, p.dataset_id AS export_dataset_id
FROM eucaim_cdm_output.surgical_procedure t
JOIN eucaim_cdm_output.patient p ON p.patient_id = t.patient_id;

DROP VIEW IF EXISTS eucaim_cdm_output.v_export_medication_administration CASCADE;
CREATE VIEW eucaim_cdm_output.v_export_medication_administration AS
SELECT t.*, p.dataset_id AS export_dataset_id
FROM eucaim_cdm_output.medication_administration t
JOIN eucaim_cdm_output.patient p ON p.patient_id = t.patient_id;

DROP VIEW IF EXISTS eucaim_cdm_output.v_export_adverse_event CASCADE;
CREATE VIEW eucaim_cdm_output.v_export_adverse_event AS
SELECT t.*, p.dataset_id AS export_dataset_id
FROM eucaim_cdm_output.adverse_event t
JOIN eucaim_cdm_output.patient p ON p.patient_id = t.patient_id;

DROP VIEW IF EXISTS eucaim_cdm_output.v_export_episode CASCADE;
CREATE VIEW eucaim_cdm_output.v_export_episode AS
SELECT t.*, p.dataset_id AS export_dataset_id
FROM eucaim_cdm_output.episode t
JOIN eucaim_cdm_output.patient p ON p.patient_id = t.patient_id;

DROP VIEW IF EXISTS eucaim_cdm_output.v_export_image_study CASCADE;
CREATE VIEW eucaim_cdm_output.v_export_image_study AS
SELECT t.*, p.dataset_id AS export_dataset_id
FROM eucaim_cdm_output.image_study t
JOIN eucaim_cdm_output.patient p ON p.patient_id = t.patient_id;

-- Rows with no patient_id of their own: the dataset is reached by following the
-- chain that leads to one. Every hop below lands on a primary key, so none of
-- these joins can multiply rows.

DROP VIEW IF EXISTS eucaim_cdm_output.v_export_episode_event CASCADE;
CREATE VIEW eucaim_cdm_output.v_export_episode_event AS
SELECT t.*, p.dataset_id AS export_dataset_id
FROM eucaim_cdm_output.episode_event t
JOIN eucaim_cdm_output.episode e ON e.episode_id = t.episode_id
JOIN eucaim_cdm_output.patient p ON p.patient_id = e.patient_id;

DROP VIEW IF EXISTS eucaim_cdm_output.v_export_image_series CASCADE;
CREATE VIEW eucaim_cdm_output.v_export_image_series AS
SELECT t.*, p.dataset_id AS export_dataset_id
FROM eucaim_cdm_output.image_series t
JOIN eucaim_cdm_output.image_study s ON s.study_uid = t.study_uid
JOIN eucaim_cdm_output.patient p ON p.patient_id = s.patient_id;

DROP VIEW IF EXISTS eucaim_cdm_output.v_export_image_modality CASCADE;
CREATE VIEW eucaim_cdm_output.v_export_image_modality AS
SELECT t.*, p.dataset_id AS export_dataset_id
FROM eucaim_cdm_output.image_modality t
JOIN eucaim_cdm_output.image_series se ON se.series_uid = t.series_uid
JOIN eucaim_cdm_output.image_study s ON s.study_uid = se.study_uid
JOIN eucaim_cdm_output.patient p ON p.patient_id = s.patient_id;

-- study_uid is not declared as a foreign key here, but it does hold the primary
-- key of image_study, so the join stays one to one.
DROP VIEW IF EXISTS eucaim_cdm_output.v_export_segmentation_series CASCADE;
CREATE VIEW eucaim_cdm_output.v_export_segmentation_series AS
SELECT t.*, p.dataset_id AS export_dataset_id
FROM eucaim_cdm_output.segmentation_series t
JOIN eucaim_cdm_output.image_study s ON s.study_uid = t.study_uid
JOIN eucaim_cdm_output.patient p ON p.patient_id = s.patient_id;

DROP VIEW IF EXISTS eucaim_cdm_output.v_export_segment CASCADE;
CREATE VIEW eucaim_cdm_output.v_export_segment AS
SELECT t.*, p.dataset_id AS export_dataset_id
FROM eucaim_cdm_output.segment t
JOIN eucaim_cdm_output.segmentation_series ss ON ss.segmentation_series_uid = t.segmentation_series_uid
JOIN eucaim_cdm_output.image_study s ON s.study_uid = ss.study_uid
JOIN eucaim_cdm_output.patient p ON p.patient_id = s.patient_id;

-- body_site is pointed AT rather than pointing anywhere, so the dataset is
-- resolved backwards from the tumor that references it. A scalar subquery, not
-- a join: two tumors sharing one body_site would otherwise export it twice.
DROP VIEW IF EXISTS eucaim_cdm_output.v_export_body_site CASCADE;
CREATE VIEW eucaim_cdm_output.v_export_body_site AS
SELECT t.*,
       (SELECT p.dataset_id
        FROM eucaim_cdm_output.tumor tu
        JOIN eucaim_cdm_output.patient p ON p.patient_id = tu.patient_id
        WHERE tu.tumor_body_site_id = t.body_site_id
        LIMIT 1) AS export_dataset_id
FROM eucaim_cdm_output.body_site t;
