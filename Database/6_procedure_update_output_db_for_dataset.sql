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
BEGIN
    -- Clealing output tables or given dataset ID  (CASCADE)
    DELETE FROM eucaim_cdm_output.dataset
    WHERE dataset_id = p_dataset_id;

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
	INSERT INTO eucaim_cdm_output.treatment(treatment_id, patient_id, treatment_type)
	SELECT ircs.TreatmentIdentifier, ocp.patient_id, 'GEN1000018'
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

	INSERT INTO eucaim_cdm_output.treatment(treatment_id, patient_id, treatment_type)
	SELECT isp.TreatmentIdentifier, ocp.patient_id, 'CLIN1004413'
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

	INSERT INTO eucaim_cdm_output.treatment(treatment_id, patient_id, treatment_type)
	SELECT icrm.TreatmentIdentifier, ocp.patient_id, 'CLIN1034187'
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

	INSERT INTO eucaim_cdm_output.procedure(procedure_id, patient_id, cancer_condition_id, procedure_code, procedure_offset_from_diagnosis, procedure_offset_unit, procedure_date, procedure_category)
	SELECT iip.ProcedureIdentifier, opcc.patient_id, opcc.cancer_condition_id, ImagingProcedureEUCAIM, iip.OffsetFromDiagnosis, iip.OffsetUnitEUCAIM, eucaim_etl_aux.parse_flexible_date(PerformedDate), ImagingProcedureCategoryCodeEUCAIM
	FROM eucaim_cdm_ingestion.ImagingProcedure iip
	JOIN eucaim_cdm_output.cancer_condition opcc ON iip.PrimaryCancerConditionIdentifier = opcc.cancer_condition_id
	JOIN eucaim_cdm_ingestion.PrimaryCancerCondition ipcc ON iip.PrimaryCancerConditionIdentifier = ipcc.Identifier
	JOIN eucaim_cdm_ingestion.CancerPatient icp ON ipcc.PatientIdentifier = icp.Identifier
	WHERE icp.DatasetIdentifier = p_dataset_id
	  AND opcc.patient_id = icp.Identifier
	  AND EXISTS (SELECT 1
	              FROM eucaim_cdm_ingestion.imagestudy iit
	              WHERE iit.imagingprocedureidentifier = iip.procedureidentifier);

	INSERT INTO eucaim_cdm_output.procedure(procedure_id, patient_id, cancer_condition_id, procedure_code, procedure_offset_from_diagnosis, procedure_offset_unit, procedure_date, procedure_category)
	SELECT crp.ProcedureIdentifier, opcc.patient_id, opcc.cancer_condition_id, ProcedureEUCAIM, OffsetFromDiagnosis, OffsetUnitEUCAIM, eucaim_etl_aux.parse_flexible_date(PerformedDate), ProcedureCategoryCodeEUCAIM
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


	UPDATE eucaim_cdm_output.cancer_condition occ
	SET procedure_id = first_procedure.procedure_id
	FROM (
		SELECT DISTINCT ON (cancer_condition_id) cancer_condition_id, procedure_id
		FROM eucaim_cdm_output.procedure
		WHERE cancer_condition_id IS NOT NULL
		ORDER BY cancer_condition_id,
		         procedure_date NULLS LAST,
		         procedure_offset_from_diagnosis NULLS LAST,
		         procedure_id
	) AS first_procedure,
	eucaim_cdm_output.patient opa
	WHERE occ.cancer_condition_id = first_procedure.cancer_condition_id
	  AND occ.patient_id = opa.patient_id
	  AND opa.dataset_id = p_dataset_id;

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
	INSERT INTO eucaim_cdm_output.image_study(study_uid, procedure_id, patient_id, ImagingTimepoint, study_offset_from_diagnosis, study_offset_unit, study_acquisition_date, study_number_of_series, study_number_of_instances)
    SELECT iis.ImageStudyUID, op.procedure_id, op.patient_id, iis.ImagingTimepoint, iis.OffsetFromDiagnosis, iis.OffsetUnitEUCAIM, eucaim_etl_aux.parse_flexible_date(iis.AcquisitionDate),
           (SELECT COUNT(*) FROM eucaim_cdm_ingestion.ImageSeries ise WHERE ise.ImageStudyUID = iis.ImageStudyUID),
           iis.NumberOfInstances
    FROM eucaim_cdm_ingestion.ImageStudy iis
	JOIN eucaim_cdm_output.procedure op ON iis.ImagingProcedureIdentifier = op.procedure_id
	                                       AND op.patient_id = iis.PatientIdentifier
	WHERE iis.DatasetIdentifier = p_dataset_id;

	INSERT INTO eucaim_cdm_output.image_series(series_uid, study_uid, series_number, series_description, series_manufacturer_name, series_acquisition_date, series_modality, series_body_site)
    SELECT iise.ImageSeriesUID, ois.study_uid, ImageSeriesNumber, Description, Manufacturer, eucaim_etl_aux.parse_flexible_date(iise.AcquisitionDate), modality, iise.BodyPart
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


	-- Episodes
	INSERT INTO eucaim_cdm_output.episode(episode_id, patient_id, episode_type_code, episode_number, episode_start_date, episode_end_date)
	SELECT iep.Identifier, PatientIdentifier, TypeEUCAIM, EpisodeNumber, eucaim_etl_aux.parse_flexible_date(StartDate), eucaim_etl_aux.parse_flexible_date(EndDate)
	FROM eucaim_cdm_ingestion.Episode iep
	WHERE iep.DatasetIdentifier = p_dataset_id;

	-- Episodes relationships
	INSERT INTO eucaim_cdm_output.episode_event(episode_id, event_table_id, event_table_name)
	SELECT episode_id, cancer_condition_id, 'cancer_condition'
	FROM eucaim_cdm_output.episode oep 
	JOIN eucaim_cdm_output.cancer_condition occ ON occ.patient_id = oep.patient_id 
	JOIN eucaim_cdm_output.patient opa ON opa.patient_id = oep.patient_id 
	WHERE opa.dataset_id = p_dataset_id;

	INSERT INTO eucaim_cdm_output.episode_event(episode_id, event_table_id, event_table_name)
	SELECT episode_id, opr.procedure_id, 'procedure'
	FROM eucaim_cdm_output.episode oep 
	JOIN eucaim_cdm_output.patient opa ON opa.patient_id = oep.patient_id 
	JOIN eucaim_cdm_output.cancer_condition occ ON occ.patient_id = oep.patient_id
	JOIN eucaim_cdm_output.procedure opr ON opr.cancer_condition_id  = occ.cancer_condition_id 
	WHERE opa.dataset_id = p_dataset_id;

	INSERT INTO eucaim_cdm_output.episode_event(episode_id, event_table_id, event_table_name)
	SELECT episode_id, treatment_id, 'treatment'
	FROM eucaim_cdm_output.episode oep 
	JOIN eucaim_cdm_output.patient opa ON opa.patient_id = oep.patient_id 
	JOIN eucaim_cdm_output.treatment otr ON otr.patient_id = oep.patient_id 
	WHERE opa.dataset_id = p_dataset_id;


	-- Update flag for this dataset_id	(currently handled in NiFi process group)

END;
$$;
