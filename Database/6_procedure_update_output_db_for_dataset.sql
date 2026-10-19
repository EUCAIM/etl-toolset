-- Ingestion stores every date as free text (column type varchar), and it arrives in at
-- least three different formats depending on the data holder: ISO (2007-01-17), DICOM
-- (20120319), and day-first slash-separated (17/11/2022, 1/3/2023). A plain cast(x AS date)
-- relies on the session's datestyle (ISO, MDY here), which reads slash dates month-first:
-- it throws for a day part > 12 (e.g. '17/11/2022' -> "date/time field value out of range",
-- which used to abort the whole dataset transform), and worse, for day <= 12 it silently
-- swaps day and month with no error at all (e.g. '1/3/2023' stored as 3 January instead of
-- 1 March). This function recognizes each format explicitly instead of trusting datestyle,
-- and returns NULL (with a warning) rather than raising for anything unrecognized, so one
-- bad date no longer discards an entire dataset's transform.
CREATE OR REPLACE FUNCTION eucaim_etl_aux.parse_flexible_date(p_raw text)
RETURNS date
LANGUAGE plpgsql
AS $func$
BEGIN
    IF p_raw IS NULL OR btrim(p_raw) = '' THEN
        RETURN NULL;
    END IF;

    IF p_raw ~ '^\d{4}-\d{2}-\d{2}$' THEN
        RETURN p_raw::date;
    END IF;

    IF p_raw ~ '^\d{8}$' THEN
        RETURN to_date(p_raw, 'YYYYMMDD');
    END IF;

    IF p_raw ~ '^\d{1,2}/\d{1,2}/\d{4}$' THEN
        RETURN to_date(p_raw, 'DD/MM/YYYY');
    END IF;

    RAISE WARNING 'parse_flexible_date: unrecognized date format ''%'', storing NULL', p_raw;
    RETURN NULL;
EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'parse_flexible_date: could not parse ''%'' (%), storing NULL', p_raw, SQLERRM;
    RETURN NULL;
END;
$func$;


CREATE OR REPLACE PROCEDURE eucaim_etl_aux.transform_dataset_v001(p_dataset_id text)
LANGUAGE plpgsql
SET search_path = eucaim_etl_aux, eucaim_cdm_ingestion, eucaim_cdm_output
AS $$
DECLARE
    v_orphan_studies INTEGER;
    v_orphan_sample  TEXT;
    v_orphan_no_tp   INTEGER;
    v_orphan_no_proc INTEGER;
    v_unlinked_events INTEGER;
    v_unlinked_sample TEXT;
    v_empty_episodes  INTEGER;
    v_seg_incomplete  INTEGER;
    v_seg_relaxed     BOOLEAN;
BEGIN
    -- Clealing output tables or given dataset ID  (CASCADE)
    DELETE FROM eucaim_cdm_output.dataset
    WHERE dataset_id = p_dataset_id;

    -- body_site is the one output table the cascade above cannot reach
    DELETE FROM eucaim_cdm_output.body_site bs
    WHERE NOT EXISTS (SELECT 1 FROM eucaim_cdm_output.tumor t
                      WHERE t.tumor_body_site_id = bs.body_site_id)
      AND NOT EXISTS (SELECT 1 FROM eucaim_cdm_output.radiotherapy r
                      WHERE r.radiotherapy_body_site_id = bs.body_site_id)
      AND NOT EXISTS (SELECT 1 FROM eucaim_cdm_output.surgical_procedure sp
                      WHERE sp.surgical_procedure_body_site_id = bs.body_site_id);

    -- Update Dataset
    INSERT INTO eucaim_cdm_output.dataset(dataset_id, dataset_title, dataset_description)
    SELECT Identifier, Title, Description
    FROM eucaim_cdm_ingestion.Dataset
    WHERE Identifier = p_dataset_id;

	-- Update CancerPatient
    INSERT INTO eucaim_cdm_output.patient(patient_id, dataset_id, patient_birth_date, patient_birth_sex, patient_ethnicity, patient_managing_organization_id, patient_diagnostic_category, patient_deceased, patient_date_of_last_contact, patient_cause_of_death)
	SELECT icp.Identifier, od.dataset_id, eucaim_etl_aux.parse_flexible_date(BirthDate), BirthSexEucaim, Ethnicity, ManagingOrganization, DiagnosticCategoryEucaim, Deceased, eucaim_etl_aux.parse_flexible_date(LastContactDate), CauseOfDeathEUCAIM
	FROM eucaim_cdm_ingestion.CancerPatient icp
	JOIN eucaim_cdm_output.dataset od ON icp.DatasetIdentifier = od.dataset_id
    WHERE icp.DatasetIdentifier = p_dataset_id;

	-- Update entities linked with CancerPatient directly: HealthStatus, TumorMarkerTest, FamilyMemberHistory, LabTestResult
	INSERT INTO eucaim_cdm_output.health_status_assessment(health_status_assessment_id, patient_id, health_status_assessment_code, health_status_assessment_value_as_number, health_status_assessment_value_as_concept, health_status_assessment_value_unit)
	SELECT ihs.Identifier, ocp.patient_id, ihs.HealthStatusEUCAIM, ihs.ValueAsNumber, ihs.ValueAsConceptEUCAIM, ihs.ValueAsConceptUnitEUCAIM
	FROM eucaim_cdm_ingestion.HealthStatus ihs
	JOIN eucaim_cdm_ingestion.CancerPatient icp ON ihs.PatientIdentifier = icp.Identifier
	JOIN eucaim_cdm_output.patient ocp ON icp.Identifier = ocp.patient_id
	WHERE icp.DatasetIdentifier = p_dataset_id;

	INSERT INTO eucaim_cdm_output.tumor_marker_test(tumor_marker_test_id, patient_id, tumor_marker_test_category, tumor_marker_test_code, tumor_marker_test_value_as_number, tumor_marker_test_value_as_concept, tumor_marker_test_value_unit, tumor_marker_test_date)
	SELECT itmt.Identifier, ocp.patient_id, CategoryEUCAIM, TumorMarkerEUCAIM, ValueAsNumber, ValueAsConceptEUCAIM, ValueAsConceptUnitEUCAIM, eucaim_etl_aux.parse_flexible_date(DateOfMarker)
	FROM eucaim_cdm_ingestion.TumorMarkerTest itmt
	JOIN eucaim_cdm_ingestion.CancerPatient icp ON itmt.PatientIdentifier = icp.Identifier
	JOIN eucaim_cdm_output.patient ocp ON icp.Identifier = ocp.patient_id
	WHERE icp.DatasetIdentifier = p_dataset_id;

	INSERT INTO eucaim_cdm_output.family_member_history(family_member_history_id, patient_id, family_member_history_relationship, family_member_history_condition_code, family_member_history_onset_age, family_member_history_onset_age_unit)
	SELECT ifmh.Identifier, ocp.patient_id, RelationshipEUCAIM, ConditionCodeEUCAIM, OnsetAge, OnsetAgeUnitEUCAIM
	FROM eucaim_cdm_ingestion.FamilyMemberHistory ifmh
	JOIN eucaim_cdm_ingestion.CancerPatient icp ON ifmh.PatientIdentifier = icp.Identifier
	JOIN eucaim_cdm_output.patient ocp ON icp.Identifier = ocp.patient_id
	WHERE icp.DatasetIdentifier = p_dataset_id;

	INSERT INTO eucaim_cdm_output.lab_test_result(lab_test_id, patient_id, lab_test_code, lab_test_value_as_concept, lab_test_value_as_number, lab_test_value_unit, lab_test_date, lab_test_offset_from_diagnosis, lab_test_offset_unit)
	SELECT iltr.Identifier, ocp.patient_id, codeEUCAIM, ValueAsConceptEUCAIM, ValueAsNumber, ValueUnitEUCAIM, eucaim_etl_aux.parse_flexible_date(DateOfTestResult), OffsetFromDiagnosis, OffsetUnitOriginal
	FROM eucaim_cdm_ingestion.LabTestResult iltr
	JOIN eucaim_cdm_ingestion.CancerPatient icp ON iltr.PatientIdentifier = icp.Identifier
	JOIN eucaim_cdm_output.patient ocp ON icp.Identifier = ocp.patient_id
	WHERE icp.DatasetIdentifier = p_dataset_id;

	-- Update treatments, linked with CancerPatient via Treatment: SurgicalProcedure, MedicationAdministration, Radiotherapy
	INSERT INTO eucaim_cdm_output.treatment(treatment_id, patient_id, treatment_type, start_date, start_offset_from_diagnosis, start_offset_unit)
	SELECT ircs.TreatmentIdentifier, ocp.patient_id, 'GEN1000018', eucaim_etl_aux.parse_flexible_date(ircs.PerformedDate), round(ircs.OffsetFromDiagnosis), ircs.OffsetUnitEUCAIM
	FROM eucaim_cdm_ingestion.RadiotherapyCourseSummary ircs
	JOIN eucaim_cdm_ingestion.CancerPatient icp ON ircs.PatientIdentifier = icp.Identifier
	JOIN eucaim_cdm_output.patient ocp ON icp.Identifier = ocp.patient_id
	WHERE icp.DatasetIdentifier = p_dataset_id;

	INSERT INTO eucaim_cdm_output.radiotherapy(treatment_id, patient_id, radiotherapy_offset_from_diagnosis, radiotherapy_offset_unit, radiotherapy_start_date, radiotherapy_modality)
	SELECT ircs.TreatmentIdentifier, ocp.patient_id, OffsetFromDiagnosis, OffsetUnitEUCAIM, eucaim_etl_aux.parse_flexible_date(PerformedDate), RadiotherapyEUCAIM
	FROM eucaim_cdm_ingestion.RadiotherapyCourseSummary ircs
	JOIN eucaim_cdm_ingestion.CancerPatient icp ON ircs.PatientIdentifier = icp.Identifier
	JOIN eucaim_cdm_output.patient ocp ON icp.Identifier = ocp.patient_id
	WHERE icp.DatasetIdentifier = p_dataset_id;

	INSERT INTO eucaim_cdm_output.treatment(treatment_id, patient_id, treatment_type, start_date, start_offset_from_diagnosis, start_offset_unit)
	SELECT isp.TreatmentIdentifier, ocp.patient_id, 'CLIN1004413', eucaim_etl_aux.parse_flexible_date(isp.PerformedDate), round(isp.OffsetFromDiagnosis), isp.OffsetUnitEUCAIM
	FROM eucaim_cdm_ingestion.SurgicalProcedure isp
	JOIN eucaim_cdm_ingestion.CancerPatient icp ON isp.PatientIdentifier = icp.Identifier
	JOIN eucaim_cdm_output.patient ocp ON icp.Identifier = ocp.patient_id
	WHERE icp.DatasetIdentifier = p_dataset_id;

	INSERT INTO eucaim_cdm_output.surgical_procedure(treatment_id, patient_id, surgical_procedure_offset_from_diagnosis, surgical_procedure_offset_from_diagnosis_unit, surgical_procedure_date, surgical_procedure_code)
	SELECT isp.TreatmentIdentifier, ocp.patient_id, OffsetFromDiagnosis, OffsetUnitEUCAIM, eucaim_etl_aux.parse_flexible_date(PerformedDate), ProcedureEUCAIM
	FROM eucaim_cdm_ingestion.SurgicalProcedure isp
	JOIN eucaim_cdm_ingestion.CancerPatient icp ON isp.PatientIdentifier = icp.Identifier
	JOIN eucaim_cdm_output.patient ocp ON icp.Identifier = ocp.patient_id
	WHERE icp.DatasetIdentifier = p_dataset_id;

	INSERT INTO eucaim_cdm_output.treatment(treatment_id, patient_id, treatment_type, start_date, start_offset_from_diagnosis, start_offset_unit)
	SELECT icrm.TreatmentIdentifier, ocp.patient_id, 'CLIN1034187', cast(icrm.DateOfMedication as date), round(icrm.OffsetFromDiagnosis), icrm.OffsetUnitEUCAIM
	FROM eucaim_cdm_ingestion.CancerRelatedMedication icrm
	JOIN eucaim_cdm_ingestion.CancerPatient icp ON icrm.PatientIdentifier = icp.Identifier
	JOIN eucaim_cdm_output.patient ocp ON icp.Identifier = ocp.patient_id
	WHERE icp.DatasetIdentifier = p_dataset_id;

	INSERT INTO eucaim_cdm_output.medication_administration(treatment_id, patient_id, start_offset_from_diagnosis, start_offset_from_diagnosis_unit, medication_start_date, medication_code)
	SELECT icrm.TreatmentIdentifier, ocp.patient_id, OffsetFromDiagnosis, OffsetUnitEUCAIM, cast(DateOfMedication as date), MedicationCodeEUCAIM
	FROM eucaim_cdm_ingestion.CancerRelatedMedication icrm
	JOIN eucaim_cdm_ingestion.CancerPatient icp ON icrm.PatientIdentifier = icp.Identifier
	JOIN eucaim_cdm_output.patient ocp ON icp.Identifier = ocp.patient_id
	WHERE icp.DatasetIdentifier = p_dataset_id;

	-- Update PrimaryCancerCondition
	INSERT INTO eucaim_cdm_output.cancer_condition(cancer_condition_id, patient_id, cancer_condition_age_at_diagnosis, cancer_condition_age_unit, cancer_condition_asserted_date, cancer_condition_code, cancer_condition_histology_morphology_behavior, cancer_condition_type)
	SELECT ipcc.Identifier, ocp.patient_id, ipcc.AgeOfDiagnosis, ipcc.AgeUnitEUCAIM, cast(ipcc.AssertedDate as date), ipcc.PrimaryCancerConditionEUCAIM, ipcc.HistologyMorphologyBehaviourEUCAIM, ipcc.PrimaryCancerConditionType
	FROM eucaim_cdm_ingestion.PrimaryCancerCondition ipcc
	JOIN eucaim_cdm_ingestion.CancerPatient icp ON ipcc.PatientIdentifier = icp.Identifier
	JOIN eucaim_cdm_output.patient ocp ON icp.Identifier = ocp.patient_id
	WHERE icp.DatasetIdentifier = p_dataset_id;

	-- Update entities linked with PrimaryCancerCondition directly: HistologicGrade, CancerStage, Procedure, ImagingProcedure, Tumor
	INSERT INTO eucaim_cdm_output.histologic_grade(histologic_grade_id, cancer_condition_id, patient_id, histologic_grade_code, histologic_grade_value_as_concept, histologic_grade_scoring_system)
	SELECT ihg.Identifier, opcc.cancer_condition_id, icp.identifier, 'CLIN1049681', GradeEUCAIM, ScoringSystemEUCAIM
	FROM eucaim_cdm_ingestion.HistologicGrade ihg
	JOIN eucaim_cdm_output.cancer_condition opcc ON ihg.PrimaryCancerConditionIdentifier = opcc.cancer_condition_id
	JOIN eucaim_cdm_ingestion.PrimaryCancerCondition ipcc ON ihg.PrimaryCancerConditionIdentifier = ipcc.Identifier
	JOIN eucaim_cdm_ingestion.CancerPatient icp ON ipcc.PatientIdentifier = icp.Identifier
	WHERE icp.DatasetIdentifier = p_dataset_id
	  AND opcc.patient_id = icp.Identifier;
	
	INSERT INTO eucaim_cdm_output.cancer_stage(cancer_stage_id, cancer_condition_id, patient_id, cancer_stage_code, cancer_stage_value_as_concept)
	SELECT ics.Identifier, opcc.cancer_condition_id, opcc.patient_id, CancerStageCodeEUCAIM, CancerStageValueEUCAIM
	FROM eucaim_cdm_ingestion.CancerStage ics
	JOIN eucaim_cdm_output.cancer_condition opcc ON ics.PrimaryCancerConditionIdentifier = opcc.cancer_condition_id
	JOIN eucaim_cdm_ingestion.PrimaryCancerCondition ipcc ON ics.PrimaryCancerConditionIdentifier = ipcc.Identifier
	JOIN eucaim_cdm_ingestion.CancerPatient icp ON ipcc.PatientIdentifier = icp.Identifier
	WHERE icp.DatasetIdentifier = p_dataset_id
	  AND opcc.patient_id = icp.Identifier;

	INSERT INTO eucaim_cdm_output.procedure(procedure_id, patient_id, procedure_code, procedure_offset_from_diagnosis, procedure_offset_unit, procedure_date, procedure_category)
	SELECT iip.ProcedureIdentifier, opcc.patient_id, ImagingProcedureEUCAIM, iip.OffsetFromDiagnosis, iip.OffsetUnitEUCAIM, eucaim_etl_aux.parse_flexible_date(PerformedDate), ImagingProcedureCategoryCodeEUCAIM
	FROM eucaim_cdm_ingestion.ImagingProcedure iip
	JOIN eucaim_cdm_output.cancer_condition opcc ON iip.PrimaryCancerConditionIdentifier = opcc.cancer_condition_id
	JOIN eucaim_cdm_ingestion.PrimaryCancerCondition ipcc ON iip.PrimaryCancerConditionIdentifier = ipcc.Identifier
	JOIN eucaim_cdm_ingestion.CancerPatient icp ON ipcc.PatientIdentifier = icp.Identifier
	WHERE icp.DatasetIdentifier = p_dataset_id
	  AND opcc.patient_id = icp.Identifier
	  AND EXISTS (SELECT 1
	              FROM eucaim_cdm_ingestion.imagestudy iit
	              WHERE iit.imagingprocedureidentifier = iip.procedureidentifier);

	INSERT INTO eucaim_cdm_output.procedure(procedure_id, patient_id, procedure_code, procedure_offset_from_diagnosis, procedure_offset_unit, procedure_date, procedure_category)
	SELECT crp.ProcedureIdentifier, opcc.patient_id, ProcedureEUCAIM, OffsetFromDiagnosis, OffsetUnitEUCAIM, eucaim_etl_aux.parse_flexible_date(PerformedDate), ProcedureCategoryCodeEUCAIM
	FROM eucaim_cdm_ingestion.CancerRelatedProcedure crp
	JOIN eucaim_cdm_output.cancer_condition opcc ON crp.PrimaryCancerConditionIdentifier = opcc.cancer_condition_id
	JOIN eucaim_cdm_ingestion.PrimaryCancerCondition ipcc ON crp.PrimaryCancerConditionIdentifier = ipcc.Identifier
	JOIN eucaim_cdm_ingestion.CancerPatient icp ON ipcc.PatientIdentifier = icp.Identifier
	WHERE icp.DatasetIdentifier = p_dataset_id
	  AND opcc.patient_id = icp.Identifier;

	INSERT INTO eucaim_cdm_output.tumor(tumor_id, tumor_identifier, patient_id, tumor_is_index, tumor_histology_morphology, tumor_volume, tumor_size_method, tumor_size_maximum_dimension, tumor_size_other_dimension, tumor_size_dimension_unit, tumor_body_site, tumor_body_site_location, tumor_body_site_laterality)
	SELECT it.Identifier, it.Identifier, opcc.patient_id, isIndex, morphologyEUCAIM, volume, sizeMethodEUCAIM, sizeMaximumDimension, sizeOtherDimension, it.sizeDimensionUnit, it.BodySiteEUCAIM, it.BodySiteLocationQualifierEUCAIM, it.BodySiteLateralityQualifierEUCAIM
	FROM eucaim_cdm_ingestion.Tumor it
	JOIN eucaim_cdm_output.cancer_condition opcc ON it.PrimaryCancerConditionIdentifier = opcc.cancer_condition_id
	JOIN eucaim_cdm_ingestion.PrimaryCancerCondition ipcc ON it.PrimaryCancerConditionIdentifier = ipcc.Identifier
	JOIN eucaim_cdm_ingestion.CancerPatient icp ON ipcc.PatientIdentifier = icp.Identifier
	WHERE icp.DatasetIdentifier = p_dataset_id
	  AND opcc.patient_id = icp.Identifier;

	-- BodySite: applying peding fixes
	INSERT INTO eucaim_cdm_output.body_site(body_site_id, body_site_code, body_site_location, body_site_laterality)
	SELECT it.Identifier || '_bodysite', NULLIF(it.BodySiteEUCAIM, ''), NULLIF(it.BodySiteLocationQualifierEUCAIM, ''), NULLIF(it.BodySiteLateralityQualifierEUCAIM, '')
	FROM eucaim_cdm_ingestion.Tumor it
	JOIN eucaim_cdm_output.tumor ot ON ot.tumor_id = it.Identifier
	JOIN eucaim_cdm_ingestion.PrimaryCancerCondition ipcc ON it.PrimaryCancerConditionIdentifier = ipcc.Identifier
	JOIN eucaim_cdm_ingestion.CancerPatient icp ON ipcc.PatientIdentifier = icp.Identifier
	WHERE icp.DatasetIdentifier = p_dataset_id
	  AND (COALESCE(it.BodySiteEUCAIM, '') <> '' OR COALESCE(it.BodySiteLocationQualifierEUCAIM, '') <> '' OR COALESCE(it.BodySiteLateralityQualifierEUCAIM, '') <> '');

	UPDATE eucaim_cdm_output.tumor ot
	SET tumor_body_site_id = bs.body_site_id
	FROM eucaim_cdm_output.body_site bs
	WHERE bs.body_site_id = ot.tumor_id || '_bodysite';


	-- The condition a procedure belongs to is only known in ingestion
	-- (PrimaryCancerConditionIdentifier); the output procedure table does not keep it.
	UPDATE eucaim_cdm_output.cancer_condition occ
	SET procedure_id = first_procedure.procedure_id
	FROM (
		SELECT DISTINCT ON (pp.cancer_condition_id) pp.cancer_condition_id, op.procedure_id
		FROM (
			SELECT ProcedureIdentifier AS procedure_id, PrimaryCancerConditionIdentifier AS cancer_condition_id
			FROM eucaim_cdm_ingestion.ImagingProcedure
			UNION ALL
			SELECT ProcedureIdentifier, PrimaryCancerConditionIdentifier
			FROM eucaim_cdm_ingestion.CancerRelatedProcedure
		) pp
		JOIN eucaim_cdm_output.procedure op ON op.procedure_id = pp.procedure_id
		ORDER BY pp.cancer_condition_id,
		         op.procedure_date NULLS LAST,
		         op.procedure_offset_from_diagnosis NULLS LAST,
		         op.procedure_id
	) AS first_procedure,
	eucaim_cdm_output.patient opa
	WHERE occ.cancer_condition_id = first_procedure.cancer_condition_id
	  AND occ.patient_id = opa.patient_id
	  AND opa.dataset_id = p_dataset_id;

	-- Tumor  is attached to the procedure that first documents its cancer condition (the one chosen just above).
	UPDATE eucaim_cdm_output.tumor ot
	SET procedure_id = occ.procedure_id
	FROM eucaim_cdm_ingestion.Tumor it
	JOIN eucaim_cdm_output.cancer_condition occ ON occ.cancer_condition_id = it.PrimaryCancerConditionIdentifier
	JOIN eucaim_cdm_output.patient opa ON opa.patient_id = occ.patient_id
	WHERE it.Identifier = ot.tumor_id
	  AND ot.patient_id = occ.patient_id
	  AND opa.dataset_id = p_dataset_id
	  AND occ.procedure_id IS NOT NULL;

	-- Update entities linked with Tumor: RiskAssessment, TumorObservation
	INSERT INTO eucaim_cdm_output.risk_assessment(risk_assessment_id, tumor_id, patient_id, risk_assessment_code, risk_assessment_value_unit, risk_assessment_value_as_concept, risk_assessment_value_as_number)
	SELECT ira.Identifier, ot.tumor_id, ot.patient_id, codeEUCAIM, valueUnit, valueAsConcept, ValueAsNumber
	FROM eucaim_cdm_ingestion.RiskAssessment ira
	JOIN eucaim_cdm_output.tumor ot ON ira.TumorIdentifier = ot.tumor_id
	JOIN eucaim_cdm_ingestion.Tumor it ON ira.TumorIdentifier = it.Identifier
	JOIN eucaim_cdm_ingestion.PrimaryCancerCondition ipcc ON it.PrimaryCancerConditionIdentifier = ipcc.Identifier
	JOIN eucaim_cdm_ingestion.CancerPatient icp ON ipcc.PatientIdentifier = icp.Identifier
	WHERE icp.DatasetIdentifier = p_dataset_id
	  AND ot.patient_id = icp.Identifier;

	INSERT INTO eucaim_cdm_output.tumor_observation(tumor_observation_id, tumor_id, patient_id, tumor_observation_code, tumor_observation_value_unit, tumor_observation_value_as_concept, tumor_observation_Value_as_number)
	SELECT ito.Identifier, ot.tumor_id, ot.patient_id, codeEUCAIM, valueUnit, valueAsConcept, ValueAsNumber
	FROM eucaim_cdm_ingestion.TumorObservation ito
	JOIN eucaim_cdm_output.tumor ot ON ito.TumorIdentifier = ot.tumor_id
	JOIN eucaim_cdm_ingestion.Tumor it ON ito.TumorIdentifier = it.Identifier
	JOIN eucaim_cdm_ingestion.PrimaryCancerCondition ipcc ON it.PrimaryCancerConditionIdentifier = ipcc.Identifier
	JOIN eucaim_cdm_ingestion.CancerPatient icp ON ipcc.PatientIdentifier = icp.Identifier
	WHERE icp.DatasetIdentifier = p_dataset_id
	  AND ot.patient_id = icp.Identifier;

	-- Update entities for DICOM metadata
	SELECT count(*) INTO v_orphan_studies
	FROM eucaim_cdm_ingestion.ImageStudy iis
	WHERE iis.DatasetIdentifier = p_dataset_id
	  AND NOT EXISTS (SELECT 1
	                  FROM eucaim_cdm_output.procedure op
	                  WHERE op.procedure_id = iis.ImagingProcedureIdentifier
	                    AND op.patient_id   = iis.PatientIdentifier);

	-- el conteo va sobre todos; la muestra para el log se corta en 10
	SELECT string_agg(t.ImageStudyUID, ', ' ORDER BY t.ImageStudyUID)
	INTO v_orphan_sample
	FROM (
		SELECT iis.ImageStudyUID
		FROM eucaim_cdm_ingestion.ImageStudy iis
		WHERE iis.DatasetIdentifier = p_dataset_id
		  AND NOT EXISTS (SELECT 1
		                  FROM eucaim_cdm_output.procedure op
		                  WHERE op.procedure_id = iis.ImagingProcedureIdentifier
		                    AND op.patient_id   = iis.PatientIdentifier)
		ORDER BY iis.ImageStudyUID
		LIMIT 10
	) t;

	IF v_orphan_studies > 0 THEN
		RAISE WARNING 'transform_dataset_v001(%): % ImageStudy sin procedure asociado se '
		              'quedan fuera de image_study (y sus series con ellos). Primeros: %. '
		              'Revisa el csv de timepoints del dataset y la tabla procedure.',
		              p_dataset_id, v_orphan_studies, v_orphan_sample;
		-- RAISE WARNING only reaches the database server log (and carries a sample of UIDs, which is
		-- fine there). The process log is what the report and the shared output folders carry, so
		-- the same finding goes there too, WITHOUT any identifier: only how many studies and why
		SELECT count(*) FILTER (WHERE iis.ImagingTimepoint IS NULL),
		       count(*) FILTER (WHERE iis.ImagingTimepoint IS NOT NULL
		                          AND NOT EXISTS (SELECT 1
		                                          FROM eucaim_cdm_ingestion.ImagingProcedure ip
		                                          JOIN eucaim_cdm_ingestion.PrimaryCancerCondition pcc
		                                            ON ip.PrimaryCancerConditionIdentifier = pcc.Identifier
		                                          WHERE pcc.PatientIdentifier = iis.PatientIdentifier
		                                            AND ip.ImagingTimepoint   = iis.ImagingTimepoint))
		INTO v_orphan_no_tp, v_orphan_no_proc
		FROM eucaim_cdm_ingestion.ImageStudy iis
		WHERE iis.DatasetIdentifier = p_dataset_id
		  AND NOT EXISTS (SELECT 1
		                  FROM eucaim_cdm_output.procedure op
		                  WHERE op.procedure_id = iis.ImagingProcedureIdentifier
		                    AND op.patient_id   = iis.PatientIdentifier);

		CALL eucaim_etl_aux.insert_log_v001(
			p_dataset_id, p_dataset_id, 'cdm_output', 'transform', '1',
			'link_image_studies', 'WARN', 'ERROR',
			format('%s ImageStudy without a linked imaging procedure are left out of the CDM, with their series: '
			       '%s have no timepoint (the timepoints csv did not reach them: its StudyInstanceUID or PatientID '
			       'differ from the DICOM metadata, or a column is missing), %s have a timepoint that no imaging '
			       'procedure of the patient has, and %s have both but are not linked. The timepoints csv needs the '
			       'columns PatientID, StudyInstanceUID and Timepoint (a whole number). scripts/check_data.sh runs '
			       'check_imaging_timepoints.sql, which breaks this down per dataset.',
			       v_orphan_studies, v_orphan_no_tp, v_orphan_no_proc,
			       v_orphan_studies - v_orphan_no_tp - v_orphan_no_proc));
	END IF;

	INSERT INTO eucaim_cdm_output.image_study(study_uid, procedure_id, patient_id, ImagingTimepoint, study_offset_from_diagnosis, study_offset_unit, study_acquisition_date, study_number_of_series, study_number_of_instances)
    SELECT iis.ImageStudyUID, op.procedure_id, op.patient_id, iis.ImagingTimepoint, iis.OffsetFromDiagnosis, iis.OffsetUnitEUCAIM, eucaim_etl_aux.parse_flexible_date(iis.AcquisitionDate),
           (SELECT COUNT(*) FROM eucaim_cdm_ingestion.ImageSeries ise WHERE ise.ImageStudyUID = iis.ImageStudyUID),
           -- NumberOfSeriesRelatedInstances es un tag POR SERIE, asi que el total del
           -- estudio es la suma sobre sus series, igual que el recuento de arriba.
           (SELECT SUM(ise.NumberOfInstances) FROM eucaim_cdm_ingestion.ImageSeries ise WHERE ise.ImageStudyUID = iis.ImageStudyUID)
    FROM eucaim_cdm_ingestion.ImageStudy iis
	JOIN eucaim_cdm_output.procedure op ON iis.ImagingProcedureIdentifier = op.procedure_id
	                                       AND op.patient_id = iis.PatientIdentifier
	WHERE iis.DatasetIdentifier = p_dataset_id;

	INSERT INTO eucaim_cdm_output.image_series(series_uid, study_uid, series_number, series_description, series_manufacturer_name, series_acquisition_date, series_modality, series_body_site, series_number_of_instances)
    SELECT iise.ImageSeriesUID, ois.study_uid, ImageSeriesNumber, Description, Manufacturer, eucaim_etl_aux.parse_flexible_date(iise.AcquisitionDate), modality, iise.BodyPart, iise.NumberOfInstances
	FROM eucaim_cdm_ingestion.ImageSeries iise
	JOIN eucaim_cdm_ingestion.ImageStudy iis ON iise.ImageStudyUID = iis.ImageStudyUID
	JOIN eucaim_cdm_output.image_study ois ON iise.ImageStudyUID = ois.study_uid
	WHERE iis.DatasetIdentifier = p_dataset_id;

	-- SliceThickness
	INSERT INTO eucaim_cdm_output.image_modality(modality_id, series_uid, study_uid, acquisition_parameter_code, acquisition_parameter_value_code, acquisition_parameter_value_number, acquisition_parameter_value_unit)
    SELECT DISTINCT ON (ois.series_uid)
           ois.series_uid || '_IMG1016306', ois.series_uid, ois.study_uid, 'IMG1016306', null, iita.SliceThickness, 'COM1000152'
	FROM eucaim_cdm_ingestion.ImageTags  iita
	JOIN eucaim_cdm_ingestion.ImageStudy iist ON iita.ImageStudyUID = iist.ImageStudyUID
	JOIN eucaim_cdm_output.image_series ois ON iita.ImageSeriesUID = ois.series_uid
	WHERE iist.DatasetIdentifier = p_dataset_id
    AND iita.SliceThickness IS NOT NULL
    ORDER BY ois.series_uid, iita.ImageStudyUID;
    
        -- EchoTime
    INSERT INTO eucaim_cdm_output.image_modality(modality_id, series_uid, study_uid, acquisition_parameter_code, acquisition_parameter_value_code, acquisition_parameter_value_number, acquisition_parameter_value_unit)
    SELECT DISTINCT ON (ois.series_uid)
           ois.series_uid || '_IMG1016641', ois.series_uid, ois.study_uid, 'IMG1016641', null, iita.EchoTime, 'COM1001955'
    FROM eucaim_cdm_ingestion.ImageTags  iita
    JOIN eucaim_cdm_ingestion.ImageStudy iist ON iita.ImageStudyUID = iist.ImageStudyUID
    JOIN eucaim_cdm_output.image_series ois ON iita.ImageSeriesUID = ois.series_uid
    WHERE iist.DatasetIdentifier = p_dataset_id
    AND iita.EchoTime IS NOT NULL
    ORDER BY ois.series_uid, iita.ImageStudyUID;

	-- CTDIvol (indice de dosis en TC)
	INSERT INTO eucaim_cdm_output.image_modality(modality_id, series_uid, study_uid, acquisition_parameter_code, acquisition_parameter_value_code, acquisition_parameter_value_number, acquisition_parameter_value_unit)
	SELECT DISTINCT ON (ois.series_uid)
	       ois.series_uid || '_IMG1000144', ois.series_uid, ois.study_uid, 'IMG1000144', null, iita.CTDIvol, 'COM1001957'
	FROM eucaim_cdm_ingestion.ImageTags  iita
	JOIN eucaim_cdm_ingestion.ImageStudy iist ON iita.ImageStudyUID = iist.ImageStudyUID
	JOIN eucaim_cdm_output.image_series ois ON iita.ImageSeriesUID = ois.series_uid
	WHERE iist.DatasetIdentifier = p_dataset_id
	AND iita.CTDIvol IS NOT NULL
	ORDER BY ois.series_uid, iita.ImageStudyUID;

	-- Exposure (IMG1016635, 'radiation exposure measure')
	INSERT INTO eucaim_cdm_output.image_modality(modality_id, series_uid, study_uid, acquisition_parameter_code, acquisition_parameter_value_code, acquisition_parameter_value_number, acquisition_parameter_value_unit)
	SELECT DISTINCT ON (ois.series_uid)
	       ois.series_uid || '_IMG1016635', ois.series_uid, ois.study_uid, 'IMG1016635', null, iita.Exposure, null
	FROM eucaim_cdm_ingestion.ImageTags  iita
	JOIN eucaim_cdm_ingestion.ImageStudy iist ON iita.ImageStudyUID = iist.ImageStudyUID
	JOIN eucaim_cdm_output.image_series ois ON iita.ImageSeriesUID = ois.series_uid
	WHERE iist.DatasetIdentifier = p_dataset_id
	AND iita.Exposure IS NOT NULL
	ORDER BY ois.series_uid, iita.ImageStudyUID;

	-- Segmentation Series
	-- El extractor entrega hoy la identidad de la serie SEG y su fecha, pero no los dos
	-- campos que el CDM marca required: source_series_uid (tag ReferencedSeriesSequence) y
	-- segmentation_algorithm_type (SegmentAlgorithmType). Ambos viven DENTRO del objeto SEG,
	-- no en sus metadatos de serie, asi que hoy llegan nulos a la ingesta.
	--
	-- Que hacer con ellas depende de la instalacion, y el procedimiento lo averigua en vez
	-- de imponerlo: si el paso 3z ha relajado los NOT NULL de esos dos campos, se publican
	-- incompletas; si no, se publican solo las que vienen completas. Preguntarlo a
	-- information_schema en lugar de asumirlo es lo que permite que el mismo procedimiento
	-- sirva a quien acepta la divergencia y a quien se queda con el CDM estricto, sin que a
	-- este ultimo le reviente el transform ENTERO por una fila de segmentacion.
	--
	-- Lo que NO se hace es rellenarlos con un valor por defecto: segmentation_algorithm_type
	-- dice si la anotacion fue automatica, semiautomatica o manual, y eso es procedencia. Un
	-- nulo se ve; un 'MANUAL' inventado se cree. El aviso de abajo cuenta cuantas filas van
	-- incompletas, que es la cifra que hara falta en esa negociacion.
	SELECT bool_and(c.is_nullable = 'YES') INTO v_seg_relaxed
	FROM information_schema.columns c
	WHERE c.table_schema = 'eucaim_cdm_output'
	  AND c.table_name   = 'segmentation_series'
	  AND c.column_name IN ('source_series_uid', 'segmentation_algorithm_type');

	INSERT INTO eucaim_cdm_output.segmentation_series(segmentation_series_uid, source_series_uid, study_uid, segmentation_algorithm_type, segmentation_performed_date)
	SELECT iseg.SegmentationSeriesUID, iseg.SourceSeriesUID, ois.study_uid, iseg.AlgorithmType,
	       eucaim_etl_aux.parse_flexible_date(iseg.AcquisitionDate)
	FROM eucaim_cdm_ingestion.SegmentationSeries iseg
	JOIN eucaim_cdm_output.image_study ois ON ois.study_uid = iseg.ImageStudyUID
	JOIN eucaim_cdm_output.patient opa ON opa.patient_id = ois.patient_id
	                                  AND opa.dataset_id = p_dataset_id
	WHERE v_seg_relaxed
	   OR (iseg.SourceSeriesUID IS NOT NULL AND iseg.AlgorithmType IS NOT NULL);

	-- Cuantas de las publicadas no cumplen el CDM. Mientras el extractor no de los dos tags
	-- seran todas; la cifra es el coste real de la divergencia.
	SELECT count(*) INTO v_seg_incomplete
	FROM eucaim_cdm_ingestion.SegmentationSeries iseg
	JOIN eucaim_cdm_output.image_study ois ON ois.study_uid = iseg.ImageStudyUID
	JOIN eucaim_cdm_output.patient opa ON opa.patient_id = ois.patient_id
	                                  AND opa.dataset_id = p_dataset_id
	WHERE iseg.SourceSeriesUID IS NULL
	   OR iseg.AlgorithmType  IS NULL;

	IF v_seg_incomplete > 0 THEN
		IF v_seg_relaxed THEN
			RAISE WARNING 'transform_dataset_v001(%): % series de segmentacion se publican SIN '
			              'source_series_uid y/o segmentation_algorithm_type, que el CDM marca '
			              'como required. Divergencia aceptada (paso 3z) a la espera de que el '
			              'extractor emita ReferencedSeriesSequence y SegmentAlgorithmType.',
			              p_dataset_id, v_seg_incomplete;
		ELSE
			RAISE WARNING 'transform_dataset_v001(%): % series de segmentacion NO se publican por '
			              'faltar source_series_uid y/o segmentation_algorithm_type, required en '
			              'el CDM. Para publicarlas incompletas, aplicar el paso 3z.',
			              p_dataset_id, v_seg_incomplete;
		END IF;
	END IF;


	-- Episodes
	INSERT INTO eucaim_cdm_output.episode(episode_id, patient_id, episode_type_code, episode_number, episode_start_date, episode_end_date)
	SELECT iep.Identifier, PatientIdentifier, TypeEUCAIM, EpisodeNumber, eucaim_etl_aux.parse_flexible_date(StartDate), eucaim_etl_aux.parse_flexible_date(EndDate)
	FROM eucaim_cdm_ingestion.Episode iep
	WHERE iep.DatasetIdentifier = p_dataset_id;

	-- Episodio overarching
	INSERT INTO eucaim_cdm_output.episode(episode_id, patient_id, episode_type_code, episode_number)
	SELECT opa.patient_id || '_episode_overarching', opa.patient_id, 'GEN1000002', NULL
	FROM eucaim_cdm_output.patient opa
	WHERE opa.dataset_id = p_dataset_id;

	UPDATE eucaim_cdm_output.episode oep
	SET episode_parent_id = oep.patient_id || '_episode_overarching'
	FROM eucaim_cdm_output.patient opa
	WHERE opa.patient_id = oep.patient_id
	  AND opa.dataset_id = p_dataset_id
	  AND oep.episode_id <> oep.patient_id || '_episode_overarching';

	-- El overarching abarca a sus hijos, así que sus fechas son las de ellos
	UPDATE eucaim_cdm_output.episode par
	SET episode_start_date = hijos.min_inicio,
	    episode_end_date   = hijos.max_fin
	FROM (
		SELECT oep.episode_parent_id,
		       min(oep.episode_start_date) AS min_inicio,
		       max(oep.episode_end_date)   AS max_fin
		FROM eucaim_cdm_output.episode oep
		JOIN eucaim_cdm_output.patient opa ON opa.patient_id = oep.patient_id
		WHERE opa.dataset_id = p_dataset_id AND oep.episode_parent_id IS NOT NULL
		GROUP BY oep.episode_parent_id
	) hijos
	WHERE par.episode_id = hijos.episode_parent_id;

	-- Episodes relationships
	DROP TABLE IF EXISTS tmp_episode_events;
	CREATE TEMP TABLE tmp_episode_events AS
	SELECT ev.* FROM (
		SELECT 'Cancer Condition'::varchar AS event_table_name, occ.cancer_condition_id::varchar AS event_table_id,
		       occ.patient_id, ipcc.EpisodeNumber AS episode_number
		FROM eucaim_cdm_ingestion.PrimaryCancerCondition ipcc
		JOIN eucaim_cdm_output.cancer_condition occ ON occ.cancer_condition_id = ipcc.Identifier
		UNION ALL
		SELECT 'Procedure', opr.procedure_id, opr.patient_id, crp.Episode
		FROM eucaim_cdm_ingestion.CancerRelatedProcedure crp
		JOIN eucaim_cdm_output.procedure opr ON opr.procedure_id = crp.ProcedureIdentifier
		UNION ALL
		SELECT 'Procedure', opr.procedure_id, opr.patient_id, iip.Episode
		FROM eucaim_cdm_ingestion.ImagingProcedure iip
		JOIN eucaim_cdm_output.procedure opr ON opr.procedure_id = iip.ProcedureIdentifier
		UNION ALL
		SELECT 'Treatment', otr.treatment_id, otr.patient_id, isp.Episode
		FROM eucaim_cdm_ingestion.SurgicalProcedure isp
		JOIN eucaim_cdm_output.treatment otr ON otr.treatment_id = isp.TreatmentIdentifier
		UNION ALL
		SELECT 'Treatment', otr.treatment_id, otr.patient_id, ircs.Episode
		FROM eucaim_cdm_ingestion.RadiotherapyCourseSummary ircs
		JOIN eucaim_cdm_output.treatment otr ON otr.treatment_id = ircs.TreatmentIdentifier
		UNION ALL
		SELECT 'Treatment', otr.treatment_id, otr.patient_id, icrm.Episode
		FROM eucaim_cdm_ingestion.CancerRelatedMedication icrm
		JOIN eucaim_cdm_output.treatment otr ON otr.treatment_id = icrm.TreatmentIdentifier
		UNION ALL
		SELECT 'Health Status Assessment', ohs.health_status_assessment_id, ohs.patient_id, ihs.Episode
		FROM eucaim_cdm_ingestion.HealthStatus ihs
		JOIN eucaim_cdm_output.health_status_assessment ohs ON ohs.health_status_assessment_id = ihs.Identifier
		UNION ALL
		SELECT 'Tumor Marker Test', otmt.tumor_marker_test_id, otmt.patient_id, itmt.Episode
		FROM eucaim_cdm_ingestion.TumorMarkerTest itmt
		JOIN eucaim_cdm_output.tumor_marker_test otmt ON otmt.tumor_marker_test_id = itmt.Identifier
		UNION ALL
		SELECT 'Tumor', ot.tumor_id, ot.patient_id, it.Episode
		FROM eucaim_cdm_ingestion.Tumor it
		JOIN eucaim_cdm_output.tumor ot ON ot.tumor_id = it.Identifier
		UNION ALL
		SELECT 'Histologic Grade', ohg.histologic_grade_id, ohg.patient_id, ipcc.EpisodeNumber
		FROM eucaim_cdm_ingestion.HistologicGrade ihg
		JOIN eucaim_cdm_output.histologic_grade ohg ON ohg.histologic_grade_id = ihg.Identifier
		JOIN eucaim_cdm_ingestion.PrimaryCancerCondition ipcc ON ipcc.Identifier = ihg.PrimaryCancerConditionIdentifier
		UNION ALL
		SELECT 'Cancer Stage', ocs.cancer_stage_id, ocs.patient_id, ipcc.EpisodeNumber
		FROM eucaim_cdm_ingestion.CancerStage ics
		JOIN eucaim_cdm_output.cancer_stage ocs ON ocs.cancer_stage_id = ics.Identifier
		JOIN eucaim_cdm_ingestion.PrimaryCancerCondition ipcc ON ipcc.Identifier = ics.PrimaryCancerConditionIdentifier
		UNION ALL
		SELECT 'Risk Assessment', ora.risk_assessment_id, ora.patient_id, it2.Episode
		FROM eucaim_cdm_ingestion.RiskAssessment ira
		JOIN eucaim_cdm_output.risk_assessment ora ON ora.risk_assessment_id = ira.Identifier
		JOIN eucaim_cdm_ingestion.Tumor it2 ON it2.Identifier = ira.TumorIdentifier
		UNION ALL
		SELECT 'Tumor Observation', oto.tumor_observation_id, oto.patient_id, it3.Episode
		FROM eucaim_cdm_ingestion.TumorObservation ito
		JOIN eucaim_cdm_output.tumor_observation oto ON oto.tumor_observation_id = ito.Identifier
		JOIN eucaim_cdm_ingestion.Tumor it3 ON it3.Identifier = ito.TumorIdentifier
		UNION ALL
		SELECT 'Lab Test Result', oltr.lab_test_id, oltr.patient_id, NULL::integer
		FROM eucaim_cdm_output.lab_test_result oltr
		UNION ALL
		SELECT 'Family Member History', ofmh.family_member_history_id, ofmh.patient_id, NULL::integer
		FROM eucaim_cdm_output.family_member_history ofmh
	) ev
	WHERE ev.patient_id IN (SELECT patient_id FROM eucaim_cdm_output.patient WHERE dataset_id = p_dataset_id);

	INSERT INTO eucaim_cdm_output.episode_event(episode_id, event_table_name, event_table_id)
	SELECT DISTINCT oep.episode_id, ev.event_table_name, ev.event_table_id
	FROM tmp_episode_events ev
	JOIN eucaim_cdm_output.episode oep ON oep.patient_id = ev.patient_id
	                                  AND oep.episode_number = ev.episode_number;

	-- Todo lo que no casa con un episodio concreto -- porque no declara ninguno, o porque
	-- declara uno que no existe -- se cuelga del overarching.
	INSERT INTO eucaim_cdm_output.episode_event(episode_id, event_table_name, event_table_id)
	SELECT DISTINCT ev.patient_id || '_episode_overarching', ev.event_table_name, ev.event_table_id
	FROM tmp_episode_events ev
	WHERE ev.episode_number IS NULL
	   OR NOT EXISTS (SELECT 1 FROM eucaim_cdm_output.episode oep
	                  WHERE oep.patient_id = ev.patient_id
	                    AND oep.episode_number = ev.episode_number);

	-- Que vayan al overarching no los hace correctos: un evento que apunta a un episodio
	-- inexistente es un error de mapeo, y seguirlo contando permite verlo. 
	SELECT count(*) INTO v_unlinked_events
	FROM tmp_episode_events ev
	WHERE ev.episode_number IS NOT NULL
	  AND NOT EXISTS (SELECT 1 FROM eucaim_cdm_output.episode oep
	                  WHERE oep.patient_id = ev.patient_id
	                    AND oep.episode_number = ev.episode_number);

	IF v_unlinked_events > 0 THEN
		SELECT string_agg(x.detalle, '; ' ORDER BY x.detalle) INTO v_unlinked_sample
		FROM (
			SELECT ev.event_table_name || ' ep=' || coalesce(ev.episode_number::text, 'NULL')
			       || ' (' || count(*) || ')' AS detalle
			FROM tmp_episode_events ev
			WHERE ev.episode_number IS NOT NULL
			  AND NOT EXISTS (SELECT 1 FROM eucaim_cdm_output.episode oep
			                  WHERE oep.patient_id = ev.patient_id
			                    AND oep.episode_number = ev.episode_number)
			GROUP BY ev.event_table_name, ev.episode_number
		) x;

		RAISE WARNING 'transform_dataset_v001(%): % eventos declaran un episodio que no existe '
		              'y se han colgado del overarching. Desglose: %. Revisa la columna Episode '
		              'de la ingesta y los episodios que genera el flow.',
		              p_dataset_id, v_unlinked_events, v_unlinked_sample;
	END IF;

	DROP TABLE tmp_episode_events;

	WITH borrados AS (
		DELETE FROM eucaim_cdm_output.episode oep
		USING eucaim_cdm_output.patient opa
		WHERE opa.patient_id = oep.patient_id
		  AND opa.dataset_id = p_dataset_id
		  AND oep.episode_id <> oep.patient_id || '_episode_overarching'
		  AND NOT EXISTS (SELECT 1 FROM eucaim_cdm_output.episode_event ee
		                  WHERE ee.episode_id = oep.episode_id)
		  AND NOT EXISTS (SELECT 1 FROM eucaim_cdm_output.episode hijo
		                  WHERE hijo.episode_parent_id = oep.episode_id)
		RETURNING 1
	)
	SELECT count(*) INTO v_empty_episodes FROM borrados;

	IF v_empty_episodes > 0 THEN
		RAISE NOTICE 'transform_dataset_v001(%): % episodios se quedaron sin ningun evento y se '
		             'han eliminado.', p_dataset_id, v_empty_episodes;
	END IF;


	-- Update flag for this dataset_id	(currently handled in NiFi process group)

END;
$$;
