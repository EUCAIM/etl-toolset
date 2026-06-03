CREATE OR REPLACE PROCEDURE eucaim_etl_aux.transform_dataset_v001(p_dataset_id text)
LANGUAGE plpgsql
SET search_path = eucaim_etl_aux, eucaim_cdm_ingestion, cdm_cdm_output
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
    INSERT INTO eucaim_cdm_output.patient(patient_id, dataset_id, patient_birth_date, patient_birth_sex, patient_ethnicity, patient_managing_organization, patient_diagnostic_category, patient_deceased, patient_date_of_last_contact, patient_cause_of_death)
	SELECT icp.Identifier, od.dataset_id, CAST(BirthDate AS date), BirthSexEucaim, Ethnicity, ManagingOrganization, DiagnosticCategoryEucaim, Deceased, CAST(LastContactDate AS date), CauseOfDeathEUCAIM
	FROM eucaim_cdm_ingestion.CancerPatient icp
	JOIN eucaim_cdm_output.dataset od ON icp.DatasetIdentifier = od.dataset_id
    WHERE icp.DatasetIdentifier = p_dataset_id;

	-- Update entities linked with CancerPatient directly: HealthStatus, TumorMarkerTest, FamilyMemberHistory, LabTestResult
	INSERT INTO eucaim_cdm_output.health_status_assessment(patient_id, assessment_code, assesment_value_as_number, assesment_value_as_concept, assesment_value_unit)
	SELECT ocp.patient_id, ihs.HealthStatusEUCAIM, ihs.ValueAsNumber, ihs.ValueAsConceptEUCAIM, ihs.ValueAsConceptUnitEUCAIM
	FROM eucaim_cdm_ingestion.HealthStatus ihs
	JOIN eucaim_cdm_ingestion.CancerPatient icp ON ihs.PatientIdentifier = icp.Identifier
	JOIN eucaim_cdm_output.patient ocp ON icp.Identifier = ocp.patient_id
	WHERE icp.DatasetIdentifier = p_dataset_id;

	INSERT INTO eucaim_cdm_output.tumor_marker_test(patient_id, tumor_marker_test_category, tumor_marker_test_code, tumor_marker_test_as_number, tumor_marker_test_as_concept, tumor_marker_test_as_unit, tumor_marker_date)
	SELECT ocp.patient_id, CategoryEUCAIM, TumorMarkerEUCAIM, ValueAsNumber, ValueAsConceptEUCAIM, ValueAsConceptUnitEUCAIM, CAST(DateOfMarker AS date)
	FROM eucaim_cdm_ingestion.TumorMarkerTest itmt
	JOIN eucaim_cdm_ingestion.CancerPatient icp ON itmt.PatientIdentifier = icp.Identifier
	JOIN eucaim_cdm_output.patient ocp ON icp.Identifier = ocp.patient_id
	WHERE icp.DatasetIdentifier = p_dataset_id;

	INSERT INTO eucaim_cdm_output.family_member_history(patient_id, family_member_relationship, family_member_condition_code, family_member_onset_age, family_member_onset_age_unit)
	SELECT ocp.patient_id, RelationshipEUCAIM, ConditionCodeEUCAIM, OnsetAge, OnsetAgeUnitEUCAIM
	FROM eucaim_cdm_ingestion.FamilyMemberHistory ifmh
	JOIN eucaim_cdm_ingestion.CancerPatient icp ON ifmh.PatientIdentifier = icp.Identifier
	JOIN eucaim_cdm_output.patient ocp ON icp.Identifier = ocp.patient_id
	WHERE icp.DatasetIdentifier = p_dataset_id;

	INSERT INTO eucaim_cdm_output.lab_test_result(patient_id, lab_test_code, lab_test_value_as_concept, lab_test_value_as_number, lab_test_value_unit, lab_test_date, lab_test_offset_from_diagnosis, lab_test_offset_unit)
	SELECT ocp.patient_id, codeEUCAIM, ValueAsConceptEUCAIM, ValueAsNumber, ValueUnitEUCAIM, CAST(DateOfTestResult AS date), OffsetFromDiagnosis, OffsetUnitOriginal
	FROM eucaim_cdm_ingestion.LabTestResult iltr
	JOIN eucaim_cdm_ingestion.CancerPatient icp ON iltr.PatientIdentifier = icp.Identifier
	JOIN eucaim_cdm_output.patient ocp ON icp.Identifier = ocp.patient_id
	WHERE icp.DatasetIdentifier = p_dataset_id;

	-- Update treatments, linked with CancerPatient via Treatment: SurgicalProcedure, MedicationAdministration, Radiotherapy
	WITH inserted_treatment as (
	INSERT INTO eucaim_cdm_output.treatment(patient_id, treatment_type, TreatmentIdentifier)
		SELECT ocp.patient_id, 'GEN1000018', ircs.treatmentidentifier 
		FROM eucaim_cdm_ingestion.RadiotherapyCourseSummary ircs
		JOIN eucaim_cdm_ingestion.CancerPatient icp ON ircs.PatientIdentifier = icp.Identifier
		JOIN eucaim_cdm_output.patient ocp ON icp.Identifier = ocp.patient_id
		WHERE icp.DatasetIdentifier = p_dataset_id
		returning treatment_id, TreatmentIdentifier)
	INSERT INTO eucaim_cdm_output.radiotherapy(treatment_id, radiotherapy_offset_from_diagnosis, radiotherapy_offset_unit, radiotherapy_start_date, radiotherapy_modality)
	SELECT inserted.treatment_id, OffsetFromDiagnosis, OffsetUnitEUCAIM, cast(PerformedDate as date), RadiotherapyEUCAIM
	FROM eucaim_cdm_ingestion.RadiotherapyCourseSummary ircs
	JOIN inserted_treatment inserted ON ircs.TreatmentIdentifier = inserted.TreatmentIdentifier;

	WITH inserted_treatment as (
	INSERT INTO eucaim_cdm_output.treatment(patient_id, treatment_type, TreatmentIdentifier)
		SELECT ocp.patient_id, 'CLIN1004413', isp.treatmentidentifier 
		FROM eucaim_cdm_ingestion.SurgicalProcedure isp
		JOIN eucaim_cdm_ingestion.CancerPatient icp ON isp.PatientIdentifier = icp.Identifier
		JOIN eucaim_cdm_output.patient ocp ON icp.Identifier = ocp.patient_id
		WHERE icp.DatasetIdentifier = p_dataset_id
		returning treatment_id, TreatmentIdentifier)
	INSERT INTO eucaim_cdm_output.surgical_procedure(treatment_id, surgical_procedure_offset_from_diagnosis, surgical_procedure_offset_from_diagnosis_unit, surgical_procedure_date, surgical_procedure_code)
	SELECT inserted.treatment_id, OffsetFromDiagnosis, OffsetUnitEUCAIM, cast(PerformedDate as date), ProcedureEUCAIM
	FROM eucaim_cdm_ingestion.SurgicalProcedure isp
	JOIN inserted_treatment inserted ON isp.TreatmentIdentifier = inserted.TreatmentIdentifier;

	WITH inserted_treatment as (
	INSERT INTO eucaim_cdm_output.treatment(patient_id, treatment_type, TreatmentIdentifier)
		SELECT ocp.patient_id, 'CLIN1034187', icrm.treatmentidentifier 
		FROM eucaim_cdm_ingestion.CancerRelatedMedication icrm
		JOIN eucaim_cdm_ingestion.CancerPatient icp ON icrm.PatientIdentifier = icp.Identifier
		JOIN eucaim_cdm_output.patient ocp ON icp.Identifier = ocp.patient_id
		WHERE icp.DatasetIdentifier = p_dataset_id
		returning treatment_id, TreatmentIdentifier)
	INSERT INTO eucaim_cdm_output.medication_administration(treatment_id, medication_offset_from_diagnosis, medication_offset_unit, medication_start_date, medication_code)
	SELECT inserted.treatment_id, OffsetFromDiagnosis, OffsetUnitEUCAIM, cast(DateOfMedication as date), MedicationCodeEUCAIM
	FROM eucaim_cdm_ingestion.CancerRelatedMedication icrm
	JOIN inserted_treatment inserted ON icrm.TreatmentIdentifier = inserted.TreatmentIdentifier;

	-- Update PrimaryCancerCondition
	INSERT INTO eucaim_cdm_output.cancer_condition(Identifier, patient_id, cancer_condition_age_at_diagnosis, cancer_condition_age_unit, cancer_condition_asserted_date, cancer_condition_code, cancer_condition_histology_morphology, cancer_condition_type)
	SELECT ipcc.Identifier, ocp.patient_id, ipcc.AgeOfDiagnosis, ipcc.AgeUnitEUCAIM, cast(ipcc.AssertedDate as date), ipcc.PrimaryCancerConditionEUCAIM, ipcc.HistologyMorphologyBehaviourEUCAIM, ipcc.PrimaryCancerConditionType
	FROM eucaim_cdm_ingestion.PrimaryCancerCondition ipcc
	JOIN eucaim_cdm_ingestion.CancerPatient icp ON ipcc.PatientIdentifier = icp.Identifier
	JOIN eucaim_cdm_output.patient ocp ON icp.Identifier = ocp.patient_id
	WHERE icp.DatasetIdentifier = p_dataset_id;

	-- Update entities linked with PrimaryCancerCondition directly: HistologicGrade, CancerStage, Procedure, ImagingProcedure, Tumor
	INSERT INTO eucaim_cdm_output.histologic_grade(cancer_condition_id, patient_id, histologic_grade_code, histologic_grade_value_as_concept, histologic_grade_scoring_system)
	SELECT opcc.cancer_condition_id, icp.identifier, 'CLIN1049681', GradeEUCAIM, ScoringSystemEUCAIM
	FROM eucaim_cdm_ingestion.HistologicGrade ihg
	JOIN eucaim_cdm_output.cancer_condition opcc ON ihg.PrimaryCancerConditionIdentifier = opcc.Identifier
	JOIN eucaim_cdm_ingestion.PrimaryCancerCondition ipcc ON ihg.PrimaryCancerConditionIdentifier = ipcc.Identifier
	JOIN eucaim_cdm_ingestion.CancerPatient icp ON ipcc.PatientIdentifier = icp.Identifier
	WHERE icp.DatasetIdentifier = p_dataset_id;
	
	INSERT INTO eucaim_cdm_output.cancer_stage(cancer_condition_id, cancer_stage_code, cancer_stage_as_concept)
	SELECT opcc.cancer_condition_id, CancerStageCodeEUCAIM, CancerStageValueEUCAIM
	FROM eucaim_cdm_ingestion.CancerStage ics
	JOIN eucaim_cdm_output.cancer_condition opcc ON ics.PrimaryCancerConditionIdentifier = opcc.Identifier
	JOIN eucaim_cdm_ingestion.PrimaryCancerCondition ipcc ON ics.PrimaryCancerConditionIdentifier = ipcc.Identifier
	JOIN eucaim_cdm_ingestion.CancerPatient icp ON ipcc.PatientIdentifier = icp.Identifier
	WHERE icp.DatasetIdentifier = p_dataset_id;

	INSERT INTO eucaim_cdm_output.procedure(patient_id, cancer_condition_id, ProcedureIdentifier, procedure_code, procedure_offset_from_diagnosis, procedure_offset_unit, procedure_date, procedure_category)
	SELECT opcc.patient_id, opcc.cancer_condition_id, ProcedureIdentifier, ImagingProcedureEUCAIM, iip.OffsetFromDiagnosis, iip.OffsetUnitEUCAIM, cast(PerformedDate as date), ImagingProcedureCategoryCodeEUCAIM
	FROM eucaim_cdm_ingestion.ImagingProcedure iip
	JOIN eucaim_cdm_output.cancer_condition opcc ON iip.PrimaryCancerConditionIdentifier = opcc.Identifier
	JOIN eucaim_cdm_ingestion.PrimaryCancerCondition ipcc ON iip.PrimaryCancerConditionIdentifier = ipcc.Identifier
	JOIN eucaim_cdm_ingestion.CancerPatient icp ON ipcc.PatientIdentifier = icp.Identifier
	JOIN eucaim_cdm_ingestion.imagestudy iit on iip.procedureidentifier  = iit.imagingprocedureidentifier 
	WHERE icp.DatasetIdentifier = p_dataset_id;

	INSERT INTO eucaim_cdm_output.procedure(patient_id, cancer_condition_id, ProcedureIdentifier, procedure_code, procedure_offset_from_diagnosis, procedure_offset_unit, procedure_date, procedure_category)
	SELECT opcc.patient_id, opcc.cancer_condition_id, ProcedureIdentifier, ProcedureEUCAIM, OffsetFromDiagnosis, OffsetUnitEUCAIM, cast(PerformedDate as date), ProcedureCategoryCodeEUCAIM
	FROM eucaim_cdm_ingestion.CancerRelatedProcedure crp
	JOIN eucaim_cdm_output.cancer_condition opcc ON crp.PrimaryCancerConditionIdentifier = opcc.Identifier
	JOIN eucaim_cdm_ingestion.PrimaryCancerCondition ipcc ON crp.PrimaryCancerConditionIdentifier = ipcc.Identifier
	JOIN eucaim_cdm_ingestion.CancerPatient icp ON ipcc.PatientIdentifier = icp.Identifier
	WHERE icp.DatasetIdentifier = p_dataset_id;

	INSERT INTO eucaim_cdm_output.tumor(Identifier, tumor_is_index, tumor_histology_morphology, tumor_volume_unit, tumor_size_method, tumor_size_maximum_dimension, tumor_size_other_dimension, tumor_body_site, tumor_body_site_location, tumor_body_site_laterality)
	SELECT it.Identifier, isIndex, morphologyEUCAIM, volume, sizeMethodEUCAIM, sizeMaximumDimension, sizeOtherDimension, it.BodySiteEUCAIM, it.BodySiteLocationQualifierEUCAIM, it.BodySiteLateralityQualifierEUCAIM
	FROM eucaim_cdm_ingestion.Tumor it
	JOIN eucaim_cdm_output.cancer_condition opcc ON it.PrimaryCancerConditionIdentifier = opcc.Identifier
	JOIN eucaim_cdm_ingestion.PrimaryCancerCondition ipcc ON it.PrimaryCancerConditionIdentifier = ipcc.Identifier
	JOIN eucaim_cdm_ingestion.CancerPatient icp ON ipcc.PatientIdentifier = icp.Identifier
	WHERE icp.DatasetIdentifier = p_dataset_id;

	-- Update entities linked with Tumor: RiskAssessment, TumorObservation
	INSERT INTO eucaim_cdm_output.risk_assessment(tumor_id, risk_assessment_code, risk_assessment_value_unit, risk_assessment_value_as_concept, risk_assessment_value_as_number)
	SELECT ot.tumor_id, codeEUCAIM, valueUnit, valueAsConcept, ValueAsNumber
	FROM eucaim_cdm_ingestion.RiskAssessment ira
	JOIN eucaim_cdm_output.tumor ot ON ira.TumorIdentifier = ot.Identifier
	JOIN eucaim_cdm_ingestion.Tumor it ON ira.TumorIdentifier = it.Identifier
	JOIN eucaim_cdm_ingestion.PrimaryCancerCondition ipcc ON it.PrimaryCancerConditionIdentifier = ipcc.Identifier
	JOIN eucaim_cdm_ingestion.CancerPatient icp ON ipcc.PatientIdentifier = icp.Identifier
	WHERE icp.DatasetIdentifier = p_dataset_id;

	INSERT INTO eucaim_cdm_output.tumor_observation(tumor_id, tumor_observation_code, tumor_observation_value_unit, tumor_observation_value_as_concept, tumor_observation_Value_as_number)
	SELECT ot.tumor_id, codeEUCAIM, valueUnit, valueAsConcept, ValueAsNumber
	FROM eucaim_cdm_ingestion.TumorObservation ito
	JOIN eucaim_cdm_output.tumor ot ON ito.TumorIdentifier = ot.Identifier
	JOIN eucaim_cdm_ingestion.Tumor it ON ito.TumorIdentifier = it.Identifier
	JOIN eucaim_cdm_ingestion.PrimaryCancerCondition ipcc ON it.PrimaryCancerConditionIdentifier = ipcc.Identifier
	JOIN eucaim_cdm_ingestion.CancerPatient icp ON ipcc.PatientIdentifier = icp.Identifier
	WHERE icp.DatasetIdentifier = p_dataset_id;

	-- Update entities for DICOM metadata
	INSERT INTO eucaim_cdm_output.image_study(procedure_id, patient_id, study_uid, ImagingTimepoint, study_offset_from_diagnosis, study_offset_unit, study_acquisition_date, study_number_of_series, study_number_of_instances)
    SELECT op.procedure_id, op.patient_id, ImageStudyUID, iis.ImagingTimepoint, iis.OffsetFromDiagnosis, iis.OffsetUnitEUCAIM, cast(iis.AcquisitionDate as date), iis.NumberOfSeries, iis.NumberOfInstances
    FROM eucaim_cdm_ingestion.ImageStudy iis
	JOIN eucaim_cdm_output.procedure op ON iis.ImagingProcedureIdentifier = op.ProcedureIdentifier
	WHERE iis.DatasetIdentifier = p_dataset_id;

	INSERT INTO eucaim_cdm_output.image_series(study_id, study_uid, series_uid, series_number, series_description, series_manufacturer, series_acquisition_date, series_modality, series_body_site)
    SELECT ois.study_id, ois.study_uid, ImageSeriesUID, ImageSeriesNumber, Description, Manufacturer, cast(iise.AcquisitionDate as date), modality, iise.BodyPart
	FROM eucaim_cdm_ingestion.ImageSeries iise
	JOIN eucaim_cdm_ingestion.ImageStudy iis ON iise.ImageStudyUID = iis.ImageStudyUID
	JOIN eucaim_cdm_output.image_study ois ON iise.ImageStudyUID = ois.study_uid
	WHERE iis.DatasetIdentifier = p_dataset_id;

	-- SliceThickness
	INSERT INTO eucaim_cdm_output.image_modality(series_id, series_uid, study_uid, acquisition_parameter_code, acquisition_parameter_value_as_code, acquisition_parameter_value_as_number, acquisition_parameter_value_unit)
    SELECT ois.series_id, iita.ImageSeriesUID, iita.ImageStudyUID, 'IMG1016306', null, SliceThickness, 'COM1000152'
	FROM eucaim_cdm_ingestion.ImageTags  iita
	JOIN eucaim_cdm_ingestion.ImageStudy iist ON iita.ImageStudyUID = iist.ImageStudyUID
	JOIN eucaim_cdm_output.image_series ois ON iita.ImageSeriesUID = ois.series_uid
	WHERE iist.DatasetIdentifier = p_dataset_id
    AND SliceThickness IS NOT NULL;
    
	-- EchoTime
    INSERT INTO eucaim_cdm_output.image_modality(series_id, series_uid, study_uid, acquisition_parameter_code, acquisition_parameter_value_as_code, acquisition_parameter_value_as_number, acquisition_parameter_value_unit)
    SELECT ois.series_id, iita.ImageSeriesUID, iita.ImageStudyUID, 'IMG1016641', null, EchoTime, 'COM1001955'
    FROM eucaim_cdm_ingestion.ImageTags  iita
    JOIN eucaim_cdm_ingestion.ImageStudy iist ON iita.ImageStudyUID = iist.ImageStudyUID
    JOIN eucaim_cdm_output.image_series ois ON iita.ImageSeriesUID = ois.series_uid
    WHERE iist.DatasetIdentifier = p_dataset_id
    AND EchoTime IS NOT NULL;


	-- Episodes
	INSERT INTO eucaim_cdm_output.episode(patient_id, episode_type_code, episode_number, episode_start_date, episode_end_date)
	SELECT PatientIdentifier, TypeOriginal, EpisodeNumber, cast(StartDate as date), cast(EndDate as date)
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
