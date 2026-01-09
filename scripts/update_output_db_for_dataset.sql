CREATE OR REPLACE PROCEDURE eucaim_etl_aux.transform_dataset_v001(p_dataset_id text)
LANGUAGE plpgsql
SET search_path = eucaim_etl_aux, eucaim_cdm_ingestion, cdm_cdm_output
AS $$
BEGIN

    -- Clealing output tables or given dataset ID  (CASCADE)
    DELETE FROM eucaim_cdm_output.Dataset
    WHERE Identifier = p_dataset_id;

    -- Update Dataset
    INSERT INTO eucaim_cdm_output.Dataset(Identifier, Title, Description)
    SELECT Identifier, Title, Description
    FROM eucaim_cdm_ingestion.Dataset
    WHERE Identifier = p_dataset_id;

	-- Update CancerPatient
    INSERT INTO eucaim_cdm_output.CancerPatient(Identifier, BirthDate, BirthSexCode, Ethnicity, ManagingOrganization, DiagnosticCategoryCode, Deceased, LastContactDate, CauseOfDeath)
	SELECT Identifier, BirthDate, BirthSexEucaim, Ethnicity, ManagingOrganization, DiagnosticCategoryEucaim, Deceased, LastContactDate, CauseOfDeath
	FROM eucaim_cdm_ingestion.CancerPatient
    WHERE DatasetIdentifier = p_dataset_id;

	-- Update entities linked with CancerPatient directly: HealthStatus, TumorMarkerTest, FamilyMemberHistory
	INSERT INTO eucaim_cdm_output.HealthStatus(PatientId, HealthStatusCode, ValueAsNumber, ValueAsConcept, ValueAsConceptUnit)
	SELECT ocp.Id, ihs.HealthStatusEUCAIM, ihs.ValueAsNumber, ihs.ValueAsConceptEUCAIM, ihs.ValueAsConceptUnitEUCAIM
	FROM eucaim_cdm_ingestion.HealthStatus ihs
	JOIN eucaim_cdm_ingestion.CancerPatient icp ON ihs.PatientIdentifier = icp.Identifier
	JOIN eucaim_cdm_output.CancerPatient ocp ON icp.Identifier = ocp.Identifier
	WHERE ihs.DatasetIdentifier = p_dataset_id;

	INSERT INTO eucaim_cdm_output.TumorMarkerTest(PatientId, Category, TumorMarkerCode, ValueAsNumber, ValueAsConcept, ValueAsConceptUnit, DateOfMarker)
	SELECT ocp.Id, CategoryEUCAIM, TumorMarkerEUCAIM, ValueAsNumber, ValueAsConceptEUCAIM, ValueAsConceptUnitEUCAIM, DateOfMarker
	FROM eucaim_cdm_ingestion.TumorMarkerTest itmt
	JOIN eucaim_cdm_ingestion.CancerPatient icp ON itmt.PatientIdentifier = icp.Identifier
	JOIN eucaim_cdm_output.CancerPatient ocp ON icp.Identifier = ocp.Identifier
	WHERE itmt.DatasetIdentifier = p_dataset_id;

	INSERT INTO eucaim_cdm_output.FamilyMemberHistory(PatientId, Subject, Relationship, ConditionCode, OnsetAge, OnsetAgeUnit)
	SELECT ocp.Id, SubjectEUCAIM, RelationshipEUCAIM, ConditionCodeEUCAIM, OnsetAge, OnsetAgeUnitEUCAIM
	FROM eucaim_cdm_ingestion.FamilyMemberHistory ifmh
	JOIN eucaim_cdm_ingestion.CancerPatient icp ON ifmh.PatientIdentifier = icp.Identifier
	JOIN eucaim_cdm_output.CancerPatient ocp ON icp.Identifier = ocp.Identifier
	WHERE ifmh.DatasetIdentifier = p_dataset_id;

	-- Update treatments, linked with CancerPatient directly: SurgicalProcedure, MedicationAdministration, Radiotherapy
	INSERT INTO eucaim_cdm_output.RadiotherapyCourseSummary(PatientId, OffsetFromDiagnosis, OffsetUnit, PerformedDate, RadiotherapyCode)
	SELECT ocp.Id, OffsetFromDiagnosis, OffsetUnitEUCAIM, PerformedDate, RadiotherapyEUCAIM
	FROM eucaim_cdm_ingestion.RadiotherapyCourseSummary ircs
	JOIN eucaim_cdm_ingestion.CancerPatient icp ON ircs.PatientIdentifier = icp.Identifier
	JOIN eucaim_cdm_output.CancerPatient ocp ON icp.Identifier = ocp.Identifier
	WHERE ircs.DatasetIdentifier = p_dataset_id;

	INSERT INTO eucaim_cdm_output.SurgicalProcedure(PatientId, OffsetFromDiagnosis, OffsetUnit, PerformedDate, ProcedureCode)
	SELECT ocp.Id, OffsetFromDiagnosis, OffsetUnitEUCAIM, PerformedDate, ProcedureEUCAIM
	FROM eucaim_cdm_ingestion.SurgicalProcedure isp
	JOIN eucaim_cdm_ingestion.CancerPatient icp ON isp.PatientIdentifier = icp.Identifier
	JOIN eucaim_cdm_output.CancerPatient ocp ON icp.Identifier = ocp.Identifier
	WHERE isp.DatasetIdentifier = p_dataset_id;

	INSERT INTO eucaim_cdm_output.CancerRelatedMedication(PatientId, OffsetFromDiagnosis, OffsetUnit, DateOfMedication, MedicationCode)
	SELECT ocp.Id, OffsetFromDiagnosis, OffsetUnitEUCAIM, DateOfMedication, MedicationCodeEUCAIM
	FROM eucaim_cdm_ingestion.CancerRelatedMedication icrm
	JOIN eucaim_cdm_ingestion.CancerPatient icp ON icrm.PatientIdentifier = icp.Identifier
	JOIN eucaim_cdm_output.CancerPatient ocp ON icp.Identifier = ocp.Identifier
	WHERE icrm.DatasetIdentifier = p_dataset_id;

	-- Update PrimaryCancerCondition
	INSERT INTO eucaim_cdm_output.PrimaryCancerCondition(Identifier, PatientId, AgeOfDiagnosis, AgeUnitCode, AssertedDate, PrimaryCancerConditionCode, HistologyMorphologyBehaviourCode, BodySiteCode, BodySiteLocationQualifierCode, BodySiteLateralityQualifierCode, EpisodeStartDate)
	SELECT ipcc.Identifier, ocp.Id, ipcc.AgeOfDiagnosis, ipcc.AgeUnitEUCAIM, ipcc.AssertedDate, ipcc.PrimaryCancerConditionEUCAIM, ipcc.HistologyMorphologyBehaviourEUCAIM, ipcc.BodySiteEUCAIM, ipcc.BodySiteLocationQualifierEUCAIM, ipcc.BodySiteLateralityQualifierEUCAIM, CAST(ipcc.EpisodeStartDate AS date)
	FROM eucaim_cdm_ingestion.PrimaryCancerCondition ipcc
	JOIN eucaim_cdm_ingestion.CancerPatient icp ON ipcc.PatientIdentifier = icp.Identifier
	JOIN eucaim_cdm_output.CancerPatient ocp ON icp.Identifier = ocp.Identifier
	WHERE ipcc.DatasetIdentifier = p_dataset_id;

	-- Update entities linked with PrimaryCancerCondition directly: HistologicGrade, CancerStage, Procedure, ImagingProcedure, Tumor
	INSERT INTO eucaim_cdm_output.HistologicGrade(PrimaryCancerConditionId, Category, GradeCode)
	SELECT opcc.Id, CategoryEUCAIM, GradeEUCAIM
	FROM eucaim_cdm_ingestion.HistologicGrade ihg
	JOIN eucaim_cdm_ingestion.PrimaryCancerCondition opcc ON ihg.PrimaryCancerConditionIdentifier = opcc.Identifier
	WHERE ihg.DatasetIdentifier = p_dataset_id;
	
	INSERT INTO eucaim_cdm_output.CancerStage(PrimaryCancerConditionId, CancerStageCode, CancerStageValue)
	SELECT opcc.Id, CancerStageCodeEUCAIM, CancerStageValueEUCAIM
	FROM eucaim_cdm_ingestion.CancerStage ics
	JOIN eucaim_cdm_ingestion.PrimaryCancerCondition opcc ON ics.PrimaryCancerConditionIdentifier = opcc.Identifier
	WHERE ics.DatasetIdentifier = p_dataset_id;

	INSERT INTO eucaim_cdm_output.CancerRelatedProcedure(PrimaryCancerConditionId, ProcedureCode, OffsetFromDiagnosis, OffsetUnit, PerformedDate, ProcedureCategoryCode)
	SELECT opcc.Id, ProcedureEUCAIM, OffsetFromDiagnosis, OffsetUnitEUCAIM, PerformedDate, ProcedureCategoryCodeEUCAIM
	FROM eucaim_cdm_ingestion.CancerRelatedProcedure icrp
	JOIN eucaim_cdm_ingestion.PrimaryCancerCondition opcc ON icrp.PrimaryCancerConditionIdentifier = opcc.Identifier
	WHERE icrp.DatasetIdentifier = p_dataset_id;

	INSERT INTO eucaim_cdm_output.ImagingProcedure(PrimaryCancerConditionId, ImagingProcedureCode, OffsetFromDiagnosis, OffsetUnit, PerformedDate, ImagingProcedureCategoryCode)
	SELECT opcc.Id, ImagingProcedureEUCAIM, OffsetFromDiagnosis, OffsetUnitEUCAIM, PerformedDate, ImagingProcedureCategoryCodeEUCAIM
	FROM eucaim_cdm_ingestion.ImagingProcedure iip
	JOIN eucaim_cdm_ingestion.PrimaryCancerCondition opcc ON iip.PrimaryCancerConditionIdentifier = opcc.Identifier
	WHERE iip.DatasetIdentifier = p_dataset_id;

	INSERT INTO eucaim_cdm_output.Tumor(Identifier, PrimaryCancerConditionId, isIndex, morphology, volume, sizeMethod, sizeMaximumDimension, sizeOtherDimension, BodySite, BodySiteLocationQualifier, BodySiteLateralityQualifier)
	SELECT it.Identifier, opcc.Id, isIndex, morphologyEUCAIM, volume, sizeMethodEUCAIM, sizeMaximumDimension, sizeOtherDimension, it.BodySiteEUCAIM, it.BodySiteLocationQualifierEUCAIM, it.BodySiteLateralityQualifierEUCAIM
	FROM eucaim_cdm_ingestion.Tumor it
	JOIN eucaim_cdm_ingestion.PrimaryCancerCondition opcc ON it.PrimaryCancerConditionIdentifier = opcc.Identifier
	WHERE it.DatasetIdentifier = p_dataset_id;

	-- Update entities linked with Tumor: RiskAssessment, TumorObservation
	INSERT INTO eucaim_cdm_output.RiskAssessment(TumorId, code, valueUnit, valueAsConcept, ValueAsNumber)
	SELECT ot.Id, codeEUCAIM, valueUnit, valueAsConcept, ValueAsNumber
	FROM eucaim_cdm_ingestion.RiskAssessment ira
	JOIN eucaim_cdm_ingestion.Tumor ot ON ira.TumorIdentifier = ot.Identifier
	WHERE ira.DatasetIdentifier = p_dataset_id;

	INSERT INTO eucaim_cdm_output.TumorObservation(TumorId, code, valueUnit, valueAsConcept, ValueAsNumber)
	SELECT ot.Id, codeEUCAIM, valueUnit, valueAsConcept, ValueAsNumber
	FROM eucaim_cdm_ingestion.TumorObservation ito
	JOIN eucaim_cdm_ingestion.Tumor ot ON ito.TumorIdentifier = ot.Identifier
	WHERE ito.DatasetIdentifier = p_dataset_id;

	-- Update entities for DICOM metadata
	INSERT INTO eucaim_cdm_output.ImageStudy(ImagingProcedureId, ImageStudyUID, ImagingTimepoint, OffsetFromDiagnosis, OffsetUnit, ImageStudyCategoryCode)
	SELECT op.Id, ImageStudyUID, iis.ImagingTimepoint, iis.OffsetFromDiagnosis, iis.OffsetUnitEUCAIM, iis.ImageStudyCategoryCode
	FROM eucaim_cdm_ingestion.ImageStudy iis
	JOIN eucaim_cdm_ingestion.ImagingProcedure op ON iis.ImagingProcedureIdentifier = op.ProcedureIdentifier
	WHERE iis.DatasetIdentifier = p_dataset_id; 

	INSERT INTO eucaim_cdm_output.ImageSeries(ImageStudyID, ImageSeriesUID, ImageSeriesNumber, Description, Manufacturer)
	SELECT iis.Id, ImageSeriesUID, ImageSeriesNumber, Description, Manufacturer
	FROM eucaim_cdm_ingestion.ImageSeries iise
	JOIN eucaim_cdm_ingestion.ImageStudy iis ON iise.ImageStudyUID = iis.ImageStudyUID
	JOIN eucaim_cdm_ingestion.ImagingProcedure op ON iis.ImagingProcedureIdentifier = op.ProcedureIdentifier
	WHERE iis.DatasetIdentifier = p_dataset_id; 

END;
$$;