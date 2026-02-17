-- Step 2 Eucaim CDM Schema definition: ingestion

CREATE SCHEMA eucaim_cdm_ingestion;

-------------------------------------------------------------------------------------------
-- Log and control
CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.ProcessLog (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    filename VARCHAR(255),
    datasetId VARCHAR(100),
    datasetType VARCHAR(100),  -- clinical_data | image_metadata | image_timepoints
    pipelineStage VARCHAR(50),  -- loop01 | loop02 | loop03 | loop04
    stepNumber INTEGER,
    stepName VARCHAR(100),
    level varchar(50),
    status VARCHAR(50),
    message TEXT,
    timestamp TIMESTAMP
);


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


CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.DatasetIngestionControl (
  DatasetIdentifier     TEXT,
  expectedRows          INTEGER,
  processedRows         INTEGER DEFAULT 0,
  status                VARCHAR(15)   -- LOADING | DONE | ERROR
);

-------------------------------------------------------------------------------------------
-- Dataset & CancerPatient

CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.Dataset (
    Id INTEGER GENERATED ALWAYS AS IDENTITY,
    Identifier VARCHAR(150) PRIMARY KEY,
    Title VARCHAR(150) NOT NULL,
    Description VARCHAR(500),
    processed BOOLEAN DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.CancerPatient (
    Id INTEGER GENERATED ALWAYS AS IDENTITY,
    Identifier VARCHAR(150) PRIMARY KEY,
    DatasetIdentifier VARCHAR(150) NOT NULL,
    BirthDate VARCHAR(15),
    BirthSexEUCAIM VARCHAR(50),
    BirthSexOriginal VARCHAR(50),
    Ethnicity VARCHAR(50),
	ManagingOrganization VARCHAR(150),
    DiagnosticCategoryEUCAIM VARCHAR(50),
    DiagnosticCategoryOriginal VARCHAR(50),
    Deceased boolean DEFAULT false,
    LastContactDate VARCHAR(15),
    CauseOfDeathEUCAIM VARCHAR(100),
    CauseOfDeathOriginal VARCHAR(100),
    processed BOOLEAN DEFAULT FALSE
);

-------------------------------------------------------------------------------------------
-- Entities related with CancerPatient directly: HealthStatus, TumorMarkerTest, FamilyMemberHistory

CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.HealthStatus (
    Id INTEGER GENERATED ALWAYS AS IDENTITY,
    Identifier VARCHAR(50) PRIMARY KEY,
    PatientIdentifier VARCHAR(150) NOT NULL,
    HealthStatusEUCAIM VARCHAR(50),
    HealthStatusOriginal VARCHAR(50),
    ValueAsNumber DECIMAL(5,2),
    ValueAsConcept INTEGER,
    ValueAsConceptEUCAIM VARCHAR(50),
    ValueAsConceptOriginal VARCHAR(50),
    ValueAsConceptUnitEUCAIM VARCHAR(50),
    ValueAsConceptUnitOriginal VARCHAR(50),
    Episode INTEGER,
    EpisodeStartDate VARCHAR(15),
    processed BOOLEAN DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.TumorMarkerTest (
    Id INTEGER GENERATED ALWAYS AS IDENTITY ,
    Identifier VARCHAR(150) PRIMARY KEY,
    PatientIdentifier VARCHAR(150) NOT NULL,
    CategoryEUCAIM VARCHAR(50),
    CategoryOriginal VARCHAR(50),
    TumorMarkerEUCAIM VARCHAR(50),
    TumorMarkerOriginal VARCHAR(50),
    ValueAsNumber DECIMAL(5,2),
    ValueAsConceptEUCAIM VARCHAR(50),
    ValueAsConceptOriginal VARCHAR(50),
    ValueAsConceptUnitEUCAIM VARCHAR(50),
    ValueAsConceptUnitOriginal VARCHAR(50),
    DateOfMarker VARCHAR(15),
    Episode INTEGER,
    EpisodeStartDate VARCHAR(15),
    processed BOOLEAN DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.FamilyMemberHistory (
    Id INTEGER GENERATED ALWAYS AS IDENTITY,
    Identifier VARCHAR(150) PRIMARY KEY,
    PatientIdentifier VARCHAR(150) NOT NULL,
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

-------------------------------------------------------------------------------------------
-- Treatments: RadiotherapyCourseSummary, SurgicalProcedure, CancerRelatedMedication

CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.RadiotherapyCourseSummary (
    Id INTEGER GENERATED ALWAYS AS IDENTITY,
    TreatmentIdentifier VARCHAR(150) PRIMARY KEY,
    PatientIdentifier VARCHAR(150) NOT NULL,
    OffsetFromDiagnosis DECIMAL(5,2),
    OffsetUnitEUCAIM VARCHAR(50),
    OffsetUnitOriginal VARCHAR(50),
    PerformedDate VARCHAR(15),
    Episode INTEGER,
    EpisodeStartDate VARCHAR(15),
    RadiotherapyEUCAIM VARCHAR(50),
    RadiotherapyOriginal VARCHAR(150),
    processed BOOLEAN DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.SurgicalProcedure (
    Id INTEGER GENERATED ALWAYS AS IDENTITY,
    TreatmentIdentifier VARCHAR(150) PRIMARY KEY,
    PatientIdentifier VARCHAR(150) NOT NULL,
    OffsetFromDiagnosis DECIMAL(5,2),
    OffsetUnitEUCAIM VARCHAR(50),
    OffsetUnitOriginal VARCHAR(50),
    PerformedDate VARCHAR(15),
    ProcedureEUCAIM VARCHAR(50),
    ProcedureOriginal VARCHAR(150),
    Episode INTEGER,
    EpisodeStartDate VARCHAR(15),
    processed BOOLEAN DEFAULT FALSE 
);

CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.CancerRelatedMedication (
    Id INTEGER GENERATED ALWAYS AS IDENTITY,
    TreatmentIdentifier VARCHAR(150) PRIMARY KEY,
    PatientIdentifier VARCHAR(150) NOT NULL,
    DateOfMedication DATE,
    OffsetFromDiagnosis DECIMAL(5,2),
    OffsetUnitEUCAIM VARCHAR(50),
    OffsetUnitOriginal VARCHAR(50),
    MedicationCodeEUCAIM VARCHAR(50),
    MedicationCodeOriginal VARCHAR(50),
    Episode INTEGER,
    EpisodeStartDate VARCHAR(15),
    processed BOOLEAN DEFAULT FALSE
);

-------------------------------------------------------------------------------------------
-- PrimaryCancerCondition, HistologicGrade, CancerStage, Procedure, ImagingProcedure, Tumor, LabTestResult

CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.PrimaryCancerCondition (
    Id INTEGER GENERATED ALWAYS AS IDENTITY,
    Identifier VARCHAR(150) PRIMARY KEY,
    PatientIdentifier VARCHAR(150) NOT NULL,
    AgeOfDiagnosis DECIMAL(5,2),
    AgeUnitEUCAIM VARCHAR(50),
    AgeUnitOriginal VARCHAR(50),
    AssertedDate DATE,
    PrimaryCancerConditionEUCAIM VARCHAR(50),
    PrimaryCancerConditionOriginal VARCHAR(50),
    HistologyMorphologyBehaviourEUCAIM VARCHAR(50),
    HistologyMorphologyBehaviourOriginal VARCHAR(50),
    EpisodeNumber INTEGER,
    EpisodeStartDate VARCHAR(15),
    ConfirmedByProcedure VARCHAR(150),
    processed BOOLEAN DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.HistologicGrade (
    Id INTEGER GENERATED ALWAYS AS IDENTITY,
	Identifier VARCHAR(150) PRIMARY KEY,
	PrimaryCancerConditionIdentifier VARCHAR(150) NOT NULL,
    CategoryEUCAIM VARCHAR(50),
    CategoryOriginal VARCHAR(50),
    GradeEUCAIM VARCHAR(50),
    GradeOriginal VARCHAR(50),
    Value INTEGER,
    processed BOOLEAN DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.CancerStage (
    Id INTEGER GENERATED ALWAYS AS IDENTITY,
    Identifier VARCHAR(150) PRIMARY KEY,
    PrimaryCancerConditionIdentifier VARCHAR(150) NOT NULL,
	CancerStageCodeEUCAIM VARCHAR(50),
    CancerStageCodeOriginal VARCHAR(50),
	CancerStageValueEUCAIM VARCHAR(50),
    CancerStageValueOriginal VARCHAR(50),
    processed BOOLEAN DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.CancerRelatedProcedure (
    Id INTEGER GENERATED ALWAYS AS IDENTITY,
    ProcedureIdentifier VARCHAR(150) PRIMARY KEY,
    PrimaryCancerConditionIdentifier VARCHAR(150) NOT NULL,
    OffsetFromDiagnosis DECIMAL(5,2),
    OffsetUnitEUCAIM VARCHAR(50),
    OffsetUnitOriginal VARCHAR(50),
    PerformedDate VARCHAR(15),
    ProcedureEUCAIM VARCHAR(50),
    ProcedureOriginal VARCHAR(150),
    Episode INTEGER,
    EpisodeStartDate VARCHAR(15),
    ProcedureCategoryCodeEUCAIM VARCHAR(50),
    ProcedureCategoryCodeOriginal VARCHAR(50),
    processed BOOLEAN DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.ImagingProcedure (
    Id INTEGER GENERATED ALWAYS AS IDENTITY,
    ProcedureIdentifier VARCHAR(150) PRIMARY KEY,
    PrimaryCancerConditionIdentifier VARCHAR(150) NOT NULL,
    Patientidentifier VARCHAR(150) NOT NULL,
    OffsetFromDiagnosis DECIMAL(5,2),
    OffsetUnitEUCAIM VARCHAR(50),
    OffsetUnitOriginal VARCHAR(50),
    PerformedDate VARCHAR(15),
    ImagingProcedureEUCAIM VARCHAR(50),
    ImagingProcedureOriginal VARCHAR(150),
    ImagingTimepoint INTEGER,
    Episode INTEGER,
    EpisodeStartDate VARCHAR(15),
    ImagingProcedureCategoryCodeEUCAIM VARCHAR(50),
    ImagingProcedureCategoryCodeOriginal VARCHAR(50),
    processed BOOLEAN DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.Tumor (
    Id INTEGER GENERATED ALWAYS AS IDENTITY,
    Identifier VARCHAR(150) PRIMARY KEY,
    PrimaryCancerConditionIdentifier VARCHAR(150) NOT NULL,
	isIndex BOOLEAN,
	morphologyOriginal VARCHAR(150),
	morphologyEUCAIM VARCHAR(150),
	volume DECIMAL(5,2),
	sizeMethodEUCAIM VARCHAR (50),
    sizeMethodOriginal VARCHAR (50),
	sizeMaximumDimension DECIMAL(5,2),
	sizeOtherDimension DECIMAL(5,2),
	sizeDimensionUnit VARCHAR (15),
    BodySiteEUCAIM VARCHAR(50),
    BodySiteOriginal VARCHAR(50),
    BodySiteLocationQualifierEUCAIM VARCHAR(50),
    BodySiteLocationQualifierOriginal VARCHAR(50),
    BodySiteLateralityQualifierEUCAIM VARCHAR(50),
    BodySiteLateralityQualifierOriginal VARCHAR(50),
	HistologicGradeEUCAIM VARCHAR(50),
    HistologicGradeOriginal VARCHAR(50),
    Episode INTEGER,
    EpisodeStartDate VARCHAR(15),
    processed BOOLEAN DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.LabTestResult (
    Id INTEGER GENERATED ALWAYS AS IDENTITY,
    Identifier VARCHAR(150) PRIMARY KEY,
    PatientIdentifier VARCHAR(150) NOT NULL,
    codeOriginal VARCHAR(150),
    codeEUCAIM VARCHAR(150),
    ValueAsNumber DECIMAL(5,2),
    ValueAsConceptEUCAIM VARCHAR(50),
    ValueAsConceptOriginal VARCHAR(50),
    ValueUnitEUCAIM VARCHAR(50),
    ValueUnitOriginal VARCHAR(50),
    DateOfTestResult VARCHAR(15),
    OffsetFromDiagnosis DECIMAL(5,2),
    OffsetUnitEUCAIM VARCHAR(50),
    OffsetUnitOriginal VARCHAR(50),
    processed BOOLEAN DEFAULT FALSE
);

-------------------------------------------------------------------------------------------
-- Entities related with Tumor directly: RiskAssessment, TumorObservation

CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.RiskAssessment (
    Id INTEGER GENERATED ALWAYS AS IDENTITY,
	Identifier VARCHAR(150) PRIMARY KEY,
    TumorIdentifier VARCHAR(150) NOT NULL,    
	codeOriginal VARCHAR(150),
	codeEUCAIM VARCHAR(150),
	valueUnit VARCHAR (15),
    valueAsConcept VARCHAR(50),
    ValueAsNumber Integer,
    processed BOOLEAN DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.TumorObservation (
    Id INTEGER GENERATED ALWAYS AS IDENTITY,
	Identifier VARCHAR(150) PRIMARY KEY,
    TumorIdentifier VARCHAR(150) NOT NULL,
	codeOriginal VARCHAR(150),
	codeEUCAIM VARCHAR(150),
	valueUnit VARCHAR (15),
    valueAsConcept VARCHAR(50),
    ValueAsNumber Integer,
    processed BOOLEAN DEFAULT FALSE	  
);

-------------------------------------------------------------------------------------------
-- Episode

CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.Episode (
    Id INTEGER GENERATED ALWAYS AS IDENTITY,
    Identifier VARCHAR(150) PRIMARY KEY,
	PatientIdentifier VARCHAR(150) NOT NULL,
    DatasetIdentifier VARCHAR(150) NOT NULL,
    TypeEUCAIM VARCHAR(50),
    TypeOriginal VARCHAR(50) NOT NULL,
	EpisodeNumber INTEGER,
    StartDate VARCHAR(15),
    EndDate VARCHAR(15),
    ParentEpisodeId INTEGER,
    processed BOOLEAN DEFAULT FALSE
);

-------------------------------------------------------------------------------------------
-- Entities for DICOM metadata

CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.ImageStudy (
    Id INTEGER GENERATED ALWAYS AS IDENTITY,
    ImageStudyUID VARCHAR(70) PRIMARY KEY,
    ImagingTimepoint INTEGER,
    PatientIdentifier VARCHAR(150),
    DatasetIdentifier VARCHAR(150),
    OffsetFromDiagnosis DECIMAL(5,2),
    OffsetUnitEUCAIM  VARCHAR(20),
    OffsetUnitOriginal  VARCHAR(20),
    ImagingProcedureIdentifier VARCHAR(250),
    ImageStudyCategoryCode VARCHAR(70),
    processed BOOLEAN DEFAULT FALSE

);


CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.ImageSeries (
    Id INTEGER GENERATED ALWAYS AS IDENTITY,
    ImageStudyUID VARCHAR(70),
    ImageSeriesUID VARCHAR(70) PRIMARY KEY,
    ImageSeriesNumber INTEGER,
    Description VARCHAR(170),
	Manufacturer VARCHAR(70),
    processed BOOLEAN DEFAULT FALSE
);


CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.ImageTags (
    Id INTEGER GENERATED ALWAYS AS IDENTITY,
    ImageSeriesIdentifier INTEGER,
    ImageStudyUID VARCHAR(70),
    ImageSeriesUID VARCHAR(70),
    KVP DECIMAL(5,1),
    XRayTubeCurrent INTEGER,
    Exposure INTEGER,
    ExposureTime INTEGER,
    SpiralPitchFactor DECIMAL(6,4),
    FilterType VARCHAR(30),
    ConvolutionKernel VARCHAR(30),
    SliceThickness DECIMAL(5,2),
    ImageRows INTEGER,
    ImageColumns INTEGER,
    PixelRowSpacing DECIMAL(6,4),
    PixelColSpacing DECIMAL(6,4),
    processed BOOLEAN DEFAULT FALSE, 
    PRIMARY KEY (ImageStudyUID, ImageSeriesUID)
);

-------------------------------------------------------------------------------------------
