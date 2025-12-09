-- Step 2 Eucaim CDM Schema definition: ingestion

CREATE SCHEMA eucaim_cdm_ingestion;




-------------------------------------------------------------------------------------------


CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.MappedCodeableConceptsResults (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    datasetId VARCHAR(50),

    propertyNameOriginal VARCHAR(200),

    propertyNameEUCAIM VARCHAR(100),

    originalValue VARCHAR(150),

    parsedValue VARCHAR(150),

    codeInEUCAIM VARCHAR(50),

    codeCandidatesInEUCAIM VARCHAR(50),

    mappingTimestamp VARCHAR(50),

    processed BOOLEAN DEFAULT FALSE
);




-------------------------------------------------------------------------------------------



-- eucaim_cdm_ingestion.Organization

-- Cancer Patient, unique identifier. 

-- Min data, age does not go here, BirthDate is NOT required

CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.CancerPatient (

    Identifier VARCHAR(150) NOT NULL,

    DatasetIdentifier VARCHAR(150) NOT NULL,

    BirthDate VARCHAR(15),

    BirthSexEucaim VARCHAR(50),

    BirthSexOriginal VARCHAR(50),

    Ethnicity VARCHAR(50),

	ManagingOrganization VARCHAR(50),

    DiagnosticCategoryEucaim VARCHAR(50),

    DiagnosticCategoryOriginal VARCHAR(50),

    Deceased boolean DEFAULT false,

    LastContactDate VARCHAR(15),

    CauseOfDeath INTEGER,

    processed BOOLEAN DEFAULT FALSE,

    PRIMARY KEY (Identifier, DatasetIdentifier)
);





CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.Dataset (

    Identifier VARCHAR(150) PRIMARY KEY,

    Title VARCHAR(150),

    Description VARCHAR(500),

    processed BOOLEAN DEFAULT FALSE

);





-- Primary Cancer Condition of a Patient

-- Has either age of diagnosis in years or date of diagnosis

CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.PrimaryCancerCondition (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    Identifier VARCHAR(150),

    AgeOfDiagnosis DECIMAL(5,2),

    AgeUnitEUCAIM VARCHAR(50),

    AgeUnitOriginal VARCHAR(50),

    AssertedDate DATE,

	PatientIdentifier VARCHAR(150),

    DatasetIdentifier VARCHAR(150),

    PrimaryCancerConditionEUCAIM VARCHAR(50),

    PrimaryCancerConditionOriginal VARCHAR(50),

    HistologyMorphologyBehaviourEUCAIM VARCHAR(50),

    HistologyMorphologyBehaviourOriginal VARCHAR(50),

    BodySiteEUCAIM VARCHAR(50),

    BodySiteOriginal VARCHAR(50),

    BodySiteLocationQualifierEUCAIM VARCHAR(50),

    BodySiteLocationQualifierOriginal VARCHAR(50),

    BodySiteLateralityQualifierEUCAIM VARCHAR(50),

    BodySiteLateralityQualifierOriginal VARCHAR(50),

    EpisodeNumber INTEGER,

    EpisodeStartDate VARCHAR(15),

    ConfirmedByProcedure VARCHAR(150),

    processed BOOLEAN DEFAULT FALSE

);





CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.HealthStatus (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    Identifier VARCHAR(50),

    PatientIdentifier VARCHAR(150),

    DatasetIdentifier VARCHAR(150),

    HealthStatusCode INTEGER,

    HealthStatusEUCAIM VARCHAR(50),

    HealthStatusOriginal VARCHAR(50),

    ValueAsNumber DECIMAL(5,2),

    ValueAsConcept INTEGER,

    ValueAsConceptEUCAIM VARCHAR(50),

    ValueAsConceptOriginal VARCHAR(50),

    ValueAsConceptUnit INTEGER,

    processed BOOLEAN DEFAULT FALSE

);





CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.TumorMarkerTest (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    PatientIdentifier VARCHAR(150),

    DatasetIdentifier VARCHAR(150),

    PrimaryCancerIdentifier VARCHAR(150),

    CategoryEUCAIM VARCHAR(50),

    CategoryOriginal VARCHAR(50),

    TumorMarkerEUCAIM VARCHAR(50),

    TumorMarkerOriginal VARCHAR(50),

    ValueAsNumber DECIMAL(5,2),

    ValueAsConcept VARCHAR(50),

    ValueAsConceptUnit VARCHAR(50),

    DateOfMarker VARCHAR(15),

    processed BOOLEAN DEFAULT FALSE

);



CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.Tumor (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

	DatasetIdentifier VARCHAR(150),

    PrimaryCancerIdentifier VARCHAR(150),

	isIndex BOOLEAN,

	morphologyOriginal VARCHAR(150),

	morphologyEUCAIM VARCHAR(150),

	volume DECIMAL(5,2),

	sizeMethod VARCHAR (50),

	sizeMaximumDimension DECIMAL(5,2),

	sizeOhterDimension DECIMAL(5,2),

	sizeDimensionUnit VARCHAR (15),

    BodySiteEUCAIM VARCHAR(50),

    BodySiteOriginal VARCHAR(50),

    BodySiteLocationQualifierEUCAIM VARCHAR(50),

    BodySiteLocationQualifierOriginal VARCHAR(50),

    BodySiteLateralityQualifierEUCAIM VARCHAR(50),

    BodySiteLateralityQualifierOriginal VARCHAR(50),

	HistologicGradeEUCAIM VARCHAR(50),

    HistologicGradeOriginal VARCHAR(50),



    processed BOOLEAN DEFAULT FALSE
);



CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.RiskAssessment (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

	DatasetIdentifier VARCHAR(150),

    PrimaryCancerIdentifier VARCHAR(150),

	codeOriginal VARCHAR(150),

	codeEUCAIM VARCHAR(150),

	valueUnit VARCHAR (15),

    valueAsConcept VARCHAR(50),

    ValueAsNumber Integer,

    processed BOOLEAN DEFAULT FALSE
);



CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.TumorObservation (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

	DatasetIdentifier VARCHAR(150),

    PrimaryCancerIdentifier VARCHAR(150),

	codeOriginal VARCHAR(150),

	codeEUCAIM VARCHAR(150),

	valueUnit VARCHAR (15),

    valueAsConcept VARCHAR(50),

    ValueAsNumber Integer,

    processed BOOLEAN DEFAULT FALSE	  
);





-- Histologic Grade of a Patient, linked through Condition

-- Optionally linked with Procedure

CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.HistologicGrade (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

	PatientIdentifier VARCHAR(50),

    DatasetIdentifier VARCHAR(150),

	PrimaryCancerIdentifier VARCHAR(50),

    CategoryEUCAIM VARCHAR(50),

    CategoryOriginal VARCHAR(50),

    GradeEUCAIM VARCHAR(50),

    GradeOriginal VARCHAR(50),

    Value INTEGER,

    processed BOOLEAN DEFAULT FALSE
);



CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.FamilyMemberHistory (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    PatientIdentifier VARCHAR(150),

    DatasetIdentifier VARCHAR(150),

    FamiliMemberIdentifier VARCHAR(150),

    SubjectEUCAIM VARCHAR(50),

    SubjectOriginal VARCHAR(50),

    RelationshipEUCAIM VARCHAR(50),

    RelationshipOriginal VARCHAR(50),

    ConditionCodeEUCAIM VARCHAR(50),

    ConditionCodeOriginal VARCHAR(50),

    OnsetAge INTEGER,

    OnsetAgeUnitEUCAIM VARCHAR(50),

    OnsetAgeUnitOriginal VARCHAR(50),

    processed BOOLEAN DEFAULT FALSE
);





-- Procedure

-- Has either elapsed interval after baseline, in monts, or date of procedure

-- Probably it will be easier to cover at least ProcedureCategoryCode, meant to be a broader concept (i.e. Biopsy) than ProcedureCode (i.e. MRI-US fusion guided prostate biopsy)

CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.CancerRelatedProcedure (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    ProcedureIdentifier VARCHAR(150),

    OffsetFromDiagnosis DECIMAL(5,2),

    OffsetUnitEUCAIM VARCHAR(50),

    OffsetUnitOriginal VARCHAR(50),

    PerformedDate VARCHAR(15),

	PatientIdentifier VARCHAR(150),

    DatasetIdentifier VARCHAR(150),

    ProcedureEUCAIM VARCHAR(50),

    ProcedureOriginal VARCHAR(150),

    Episode INTEGER,

    EpisodeStartDate VARCHAR(15),

    ProcedureCategoryCodeEUCAIM VARCHAR(50),

    ProcedureCategoryCodeOriginal VARCHAR(50),

    processed BOOLEAN DEFAULT FALSE

);





CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.ImagingProcedure (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    ProcedureIdentifier VARCHAR(150),

    OffsetFromDiagnosis DECIMAL(5,2),

    OffsetUnitEUCAIM VARCHAR(50),

    OffsetUnitOriginal VARCHAR(50),

    PerformedDate VARCHAR(15),

	PatientIdentifier VARCHAR(150),

    DatasetIdentifier VARCHAR(150),

    ImagingProcedureEUCAIM VARCHAR(50),

    ImagingProcedureOriginal VARCHAR(150),

    ImagingTimepoint INTEGER,

    Episode INTEGER,

    EpisodeStartDate VARCHAR(15),

	ImagingProcedureCategoryCode INTEGER,

    processed BOOLEAN DEFAULT FALSE
);





CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.RadiotherapyCourseSummary (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    ProcedureIdentifier VARCHAR(150),

    OffsetFromDiagnosis DECIMAL(5,2),

    OffsetUnitEUCAIM VARCHAR(50),

    OffsetUnitOriginal VARCHAR(50),

    PerformedDate VARCHAR(15),

	PatientIdentifier VARCHAR(150),

    DatasetIdentifier VARCHAR(150),

    Episode INTEGER,

    EpisodeStartDate VARCHAR(15),

    RadiotherapyEUCAIM VARCHAR(50),

    RadiotherapyOriginal VARCHAR(150),

    processed BOOLEAN DEFAULT FALSE
);





CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.SurgicalProcedure (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    ProcedureIdentifier VARCHAR(150),

    OffsetFromDiagnosis DECIMAL(5,2),

    OffsetUnitEUCAIM VARCHAR(50),

    OffsetUnitOriginal VARCHAR(50),

    PerformedDate VARCHAR(15),

	PatientIdentifier VARCHAR(150),

    DatasetIdentifier VARCHAR(150),

    ProcedureEUCAIM VARCHAR(50),

    ProcedureOriginal VARCHAR(150),

    Episode INTEGER,

    EpisodeStartDate VARCHAR(15),

    processed BOOLEAN DEFAULT FALSE

);





CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.CancerRelatedMedication (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    DatasetIdentifier VARCHAR(150),

    DateOfMedication DATE,

    OffsetFromDiagnosis DECIMAL(5,2),

    OffsetUnitEUCAIM VARCHAR(50),

    OffsetUnitOriginal VARCHAR(50),

	PatientIdentifier VARCHAR(50),

    MedicationCodeEUCAIM VARCHAR(50),

    MedicationCodeOriginal VARCHAR(50),

    processed BOOLEAN DEFAULT FALSE

);





-- Cancer Stage, linked via Procedure, not directly to Patient

-- Optional link to Condition ?

CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.CancerStage (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    PatientIdentifier VARCHAR(150),

    DatasetIdentifier VARCHAR(150),

    PrimaryCancerConditionIdentifier VARCHAR(150),

	CancerStageCodeEUCAIM VARCHAR(50),

    CancerStageCodeOriginal VARCHAR(50),

	CancerStageValue VARCHAR(50),

    processed BOOLEAN DEFAULT FALSE

);





CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.Episode (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

	PatientIdentifier VARCHAR(150),

    DatasetIdentifier VARCHAR(150),

    TypeEUCAIM VARCHAR(50),

    TypeOriginal VARCHAR(50),

	EpisodeNumber INTEGER,

    StartDate VARCHAR(15),

    EndDate VARCHAR(15),

    ParentEpisodeId INTEGER,

    processed BOOLEAN DEFAULT FALSE

);





CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.ImageStudy (

    ImageStudyUID VARCHAR(70) PRIMARY KEY,

    ImagingTimepoint INTEGER,

    PatientIdentifier VARCHAR(150),

    DatasetIdentifier VARCHAR(150),

    OffsetFromDiagnosis DECIMAL(5,2),

    OffsetUnit INTEGER,

    ImagingProcedureIdentifier VARCHAR(50),

    ImageStudyCategoryCode INTEGER,

    processed BOOLEAN DEFAULT FALSE

);





CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.ImageSeries (

    ImageStudyUID VARCHAR(70),

    ImageSeriesUID VARCHAR(70),

    ImageSeriesNumber INTEGER,

    Description VARCHAR(170),

	Manufacturer VARCHAR(70),

    ModalityParameterCodeEUCAIM VARCHAR(50),

    ModalityParameterCodeOriginal VARCHAR(50),

    ModalityParameterValueAsCodeEUCAIM VARCHAR(50),

    ModalityParameterValueAsCodeOriginal VARCHAR(50),

    ModalityParameterValueAsNumber DECIMAL(5,2),

    ModalityParameterValueUniEUCAIM VARCHAR(50),

    ModalityParameterValueUniOriginal VARCHAR(50),

    processed BOOLEAN DEFAULT FALSE,

    PRIMARY KEY (ImageStudyUID, ImageSeriesUID)
);





CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.ImageModality (

    ImageStudyUID VARCHAR(70),

    ImageSeriesUID VARCHAR(70),

    ModalityParameterCodeEUCAIM VARCHAR(50),

    ModalityParameterCodeOriginal VARCHAR(50),

    ModalityParameterValueAsCodeEUCAIM VARCHAR(50),

    ModalityParameterValueAsCodeOriginal VARCHAR(50),

    ModalityParameterValueAsNumber DECIMAL(5,2),

    ModalityParameterValueUniEUCAIM VARCHAR(50),

    ModalityParameterValueUniOriginal VARCHAR(50),

    processed BOOLEAN DEFAULT FALSE

);





CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.ImageTags (

    ImageSeriesIdentifier INTEGER,

    ImageStudyUID VARCHAR(70),

    ImageSeriesUID VARCHAR(70),

    SliceThickness DECIMAL(5,2),

    PixelRowSpacing DECIMAL(6,4),

    PixelColSpacing DECIMAL(6,4),

    ImageRows INTEGER,

    ImageColumns INTEGER,

    KVP DECIMAL(5,1),

    XRayTubeCurrent INTEGER,

    Exposure INTEGER,

    ExposureTime INTEGER,

    SpiralPitchFactor DECIMAL(6,4),

    FilterType VARCHAR(30),

    ConvolutionKernel VARCHAR(30),

    processed BOOLEAN DEFAULT FALSE, 

    PRIMARY KEY (ImageSeriesIdentifier, ImageStudyUID, ImageSeriesUID)

);



----------------------------------------------------



ALTER TABLE eucaim_cdm_ingestion.CancerPatient

ADD CONSTRAINT unique_cancerpatient

UNIQUE (identifier, datasetidentifier);



ALTER TABLE eucaim_cdm_ingestion.Dataset

ADD CONSTRAINT unique_dataset

UNIQUE (identifier);



ALTER TABLE eucaim_cdm_ingestion.PrimaryCancerCondition

ADD CONSTRAINT unique_primarycancercondition

UNIQUE (patientidentifier, datasetidentifier, identifier, episodestartdate);



ALTER TABLE eucaim_cdm_ingestion.HealthStatus

ADD CONSTRAINT unique_healthstatus

UNIQUE (patientidentifier, datasetidentifier, identifier);



ALTER TABLE eucaim_cdm_ingestion.TumorMarkerTest

ADD CONSTRAINT unique_tumormarkertest

UNIQUE (patientidentifier, datasetidentifier, primarycanceridentifier, tumormarkeroriginal, dateofmarker);



ALTER TABLE eucaim_cdm_ingestion.FamilyMemberHistory

ADD CONSTRAINT unique_familymemberhistory

UNIQUE (patientidentifier, datasetidentifier, FamiliMemberIdentifier);



ALTER TABLE eucaim_cdm_ingestion.HistologicGrade

ADD CONSTRAINT unique_histologicgrade

UNIQUE (patientidentifier, datasetidentifier, primarycanceridentifier);



ALTER TABLE eucaim_cdm_ingestion.CancerRelatedProcedure

ADD CONSTRAINT unique_cancerrelatedprocedure

UNIQUE (patientidentifier, datasetidentifier, procedureidentifier);



ALTER TABLE eucaim_cdm_ingestion.ImagingProcedure

ADD CONSTRAINT unique_imagingprocedure

UNIQUE (patientidentifier, datasetidentifier, procedureidentifier);



ALTER TABLE eucaim_cdm_ingestion.RadiotherapyCourseSummary

ADD CONSTRAINT unique_radiotherapycoursesummary

UNIQUE (patientidentifier, datasetidentifier, procedureidentifier);



ALTER TABLE eucaim_cdm_ingestion.SurgicalProcedure

ADD CONSTRAINT unique_surgicalprocedure

UNIQUE (patientidentifier, datasetidentifier, procedureidentifier);



ALTER TABLE eucaim_cdm_ingestion.ImageStudy

ADD CONSTRAINT unique_imagestudy

UNIQUE (imagestudyuid);



ALTER TABLE eucaim_cdm_ingestion.ImageSeries

ADD CONSTRAINT unique_imageseries

UNIQUE (imagestudyuid, imageseriesuid);



ALTER TABLE eucaim_cdm_ingestion.ImageTags

ADD CONSTRAINT unique_imagetags

UNIQUE (imagestudyuid, imageseriesuid, imageseriesidentifier);



ALTER TABLE eucaim_cdm_ingestion.Episode 

ADD CONSTRAINT unique_episode

UNIQUE (patientidentifier, datasetidentifier, typeoriginal, episodenumber, startdate);



ALTER TABLE eucaim_cdm_ingestion.Tumor

ADD CONSTRAINT unique_tumor

UNIQUE (PrimaryCancerIdentifier, datasetidentifier, BodySiteOriginal);



ALTER TABLE eucaim_cdm_ingestion.CancerStage

ADD CONSTRAINT unique_cancerstage

UNIQUE (PrimaryCancerConditionId, procedureid, datasetidentifier);



ALTER TABLE eucaim_cdm_ingestion.CancerRelatedMedication

ADD CONSTRAINT unique_cancerrelatedmedication

UNIQUE (PatientIdentifier, datasetidentifier, MedicationCode);



ALTER TABLE eucaim_cdm_ingestion.RiskAssessment

ADD CONSTRAINT unique_riskassessment

UNIQUE (PrimaryCancerIdentifier, datasetidentifier, codeEUCAIM);



ALTER TABLE eucaim_cdm_ingestion.TumorObservation

ADD CONSTRAINT unique_tumorobservation

UNIQUE (PrimaryCancerIdentifier, datasetidentifier, codeEUCAIM);



----------------------------------------------------

