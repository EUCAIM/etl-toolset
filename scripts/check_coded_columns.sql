-- Finds values in the coded columns of eucaim_cdm_output that are not EUCAIM
-- concept codes: free text that never went through a lookup, the 'NOT FOUND'
-- literal a missed lookup leaves behind, or a code the hyperontology has dropped.
--
-- This is the class of defect reported in the November 2026 review of the output
-- schema. It does NOT catch a value that is a real code but the wrong one for the
-- property -- a super-class such as GEN1000002 (Episode), for instance -- because
-- that needs the per-property allowed-value lists of the CDM dictionary, which
-- this repository does not hold.
--
-- Usage:
--   scripts/check_data.sh                 runs it for every dataset
--   psql ... -v dataset="'<id>'" -f scripts/check_coded_columns.sql
--   psql ... -v dataset="'<id>'" -v strict=1 -f ...   raises when it finds any,
--                                                     which is what the reference
--                                                     dump build uses to abort
--
-- Adding a coded column: put it in the list below. The scope column says how the
-- row is traced back to its dataset.

\if :{?dataset}
\else
  \set dataset NULL
\endif

\echo ''
\echo '==== Coded columns holding something that is not a EUCAIM code ===='
\echo '     every value below is free text, a lookup miss or a code that no longer'
\echo '     exists in the hyperontology'

DROP TABLE IF EXISTS chk_coded_columns;
CREATE TEMP TABLE chk_coded_columns(tbl text, col text, scope text);
INSERT INTO chk_coded_columns VALUES
    ('patient','patient_birth_sex','patient'),
    ('patient','patient_gender','patient'),
    ('patient','patient_race','patient'),
    ('patient','patient_ethnicity','patient'),
    ('patient','patient_diagnostic_category','patient'),
    ('patient','patient_cause_of_death','patient'),
    ('cancer_condition','cancer_condition_age_unit','patient'),
    ('cancer_condition','cancer_condition_offset_unit','patient'),
    ('cancer_condition','cancer_condition_code','patient'),
    ('cancer_condition','cancer_condition_type','patient'),
    ('cancer_condition','cancer_condition_clinical_status','patient'),
    ('cancer_condition','cancer_condition_histology_morphology_behavior','patient'),
    ('cancer_condition','cancer_condition_topography','patient'),
    ('procedure','procedure_code','patient'),
    ('procedure','procedure_category','patient'),
    ('procedure','procedure_offset_unit','patient'),
    ('health_status_assessment','health_status_assessment_code','patient'),
    ('health_status_assessment','health_status_assessment_value_as_concept','patient'),
    ('health_status_assessment','health_status_assessment_value_unit','patient'),
    ('tumor_marker_test','tumor_marker_test_category','patient'),
    ('tumor_marker_test','tumor_marker_test_code','patient'),
    ('tumor_marker_test','tumor_marker_test_value_as_concept','patient'),
    ('tumor_marker_test','tumor_marker_test_value_unit','patient'),
    ('family_member_history','family_member_history_relationship','patient'),
    ('family_member_history','family_member_history_condition_code','patient'),
    ('family_member_history','family_member_history_onset_age_unit','patient'),
    ('lab_test_result','lab_test_code','patient'),
    ('lab_test_result','lab_test_value_as_concept','patient'),
    ('lab_test_result','lab_test_value_unit','patient'),
    ('histologic_grade','histologic_grade_scoring_system','patient'),
    ('histologic_grade','histologic_grade_code','patient'),
    ('histologic_grade','histologic_grade_value_as_concept','patient'),
    ('cancer_stage','cancer_stage_code','patient'),
    ('cancer_stage','cancer_stage_method','patient'),
    ('cancer_stage','cancer_stage_value_as_concept','patient'),
    ('tumor','tumor_histology_morphology','patient'),
    ('tumor','tumor_volume_unit','patient'),
    ('tumor','tumor_size_method','patient'),
    ('tumor','tumor_size_dimension_unit','patient'),
    ('tumor','tumor_body_site','patient'),
    ('tumor','tumor_body_site_location','patient'),
    ('tumor','tumor_body_site_laterality','patient'),
    ('risk_assessment','risk_assessment_code','patient'),
    ('risk_assessment','risk_assessment_value_unit','patient'),
    ('risk_assessment','risk_assessment_value_as_concept','patient'),
    ('tumor_observation','tumor_observation_code','patient'),
    ('tumor_observation','tumor_observation_value_unit','patient'),
    ('tumor_observation','tumor_observation_value_as_concept','patient'),
    ('treatment','treatment_type','patient'),
    ('treatment','start_offset_unit','patient'),
    ('treatment','end_offset_unit','patient'),
    ('radiotherapy','radiotherapy_modality','patient'),
    ('radiotherapy','radiotherapy_technique','patient'),
    ('radiotherapy','radiotherapy_offset_unit','patient'),
    ('radiotherapy','radiotherapy_dose_unit','patient'),
    ('surgical_procedure','surgical_procedure_code','patient'),
    ('surgical_procedure','surgical_procedure_body_site_code','patient'),
    ('surgical_procedure','surgical_procedure_body_site_location','patient'),
    ('surgical_procedure','surgical_procedure_body_site_laterality','patient'),
    ('surgical_procedure','surgical_procedure_offset_from_diagnosis_unit','patient'),
    ('medication_administration','medication_code','patient'),
    ('medication_administration','medication_dose_unit','patient'),
    ('medication_administration','medication_period_unit','patient'),
    ('medication_administration','start_offset_from_diagnosis_unit','patient'),
    ('medication_administration','end_offset_from_diagnosis_unit','patient'),
    ('episode','episode_type_code','patient'),
    ('episode','start_offset_unit','patient'),
    ('episode','end_offset_unit','patient'),
    ('image_study','study_offset_unit','patient'),
    ('image_series','series_body_site','study'),
    ('image_series','series_modality','study'),
    ('image_series','series_manufacturer_name','study'),
    ('image_modality','acquisition_parameter_code','study'),
    ('image_modality','acquisition_parameter_value_code','study'),
    ('image_modality','acquisition_parameter_value_unit','study'),
    ('body_site','body_site_code','bodysite'),
    ('body_site','body_site_location','bodysite'),
    ('body_site','body_site_laterality','bodysite'),
    ('body_site','body_site_volume_unit','bodysite');

DROP TABLE IF EXISTS chk_noncode_values;
CREATE TEMP TABLE chk_noncode_values(column_ref text, value text, rows bigint);

-- psql does not interpolate its variables inside a dollar-quoted body, so the
-- dataset has to reach the DO block through a table.
DROP TABLE IF EXISTS chk_scope;
CREATE TEMP TABLE chk_scope AS SELECT :dataset::text AS dataset_id;

DO $scan$
DECLARE
    r         record;
    v_scope   text;
    v_dataset text;
BEGIN
    SELECT dataset_id INTO v_dataset FROM chk_scope;
    FOR r IN SELECT tbl, col, scope FROM chk_coded_columns ORDER BY tbl, col LOOP
        -- no dataset given means every dataset, which is how check_data.sh calls it
        v_scope := CASE WHEN v_dataset IS NULL THEN 'TRUE' ELSE CASE r.scope
            WHEN 'patient' THEN format(
                't.patient_id IN (SELECT patient_id FROM eucaim_cdm_output.patient WHERE dataset_id = %L)',
                v_dataset)
            WHEN 'study' THEN format(
                't.study_uid IN (SELECT study_uid FROM eucaim_cdm_output.image_study st '
                'JOIN eucaim_cdm_output.patient p ON p.patient_id = st.patient_id WHERE p.dataset_id = %L)',
                v_dataset)
            WHEN 'bodysite' THEN format(
                't.body_site_id IN (SELECT tu.tumor_body_site_id FROM eucaim_cdm_output.tumor tu '
                'JOIN eucaim_cdm_output.patient p ON p.patient_id = tu.patient_id WHERE p.dataset_id = %L)',
                v_dataset)
            ELSE 'TRUE'
        END END;

        EXECUTE format($f$
            INSERT INTO chk_noncode_values
            SELECT %L, s.v, s.cnt
            FROM (SELECT t.%I::text AS v, count(*) AS cnt
                    FROM eucaim_cdm_output.%I t
                   WHERE t.%I IS NOT NULL AND btrim(t.%I::text) <> '' AND %s
                   GROUP BY 1) s
            WHERE NOT EXISTS (SELECT 1 FROM eucaim_hyperontology_codes.concept c
                               WHERE c.concept_code = s.v)
        $f$, r.tbl || '.' || r.col, r.col, r.tbl, r.col, r.col, v_scope);
    END LOOP;
END
$scan$;

SELECT column_ref, value, rows FROM chk_noncode_values ORDER BY column_ref, value;

\if :{?strict}
DO $strict$
DECLARE
    v_bad BIGINT;
BEGIN
    SELECT COUNT(*) INTO v_bad FROM chk_noncode_values;
    IF v_bad > 0 THEN
        RAISE EXCEPTION
            '% coded column value(s) are not EUCAIM concept codes. See the table above.', v_bad;
    END IF;
    RAISE NOTICE 'No coded column carries free text.';
END
$strict$;
\endif
