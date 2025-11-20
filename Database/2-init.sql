-- Step 2 Eucaim CDM Schema definition 
CREATE SCHEMA eucaim_cdm_ingestion;



-- Values of type CodeableConcept, each one will containt atleast the TextValue and hopefully a coded value
CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.ValueAsCodeableConcept (
    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    OriginalTextValue VARCHAR(255),
	Code INTEGER,
    mappingState VARCHAR(50),
    count INTEGER DEFAULT 0,
    FOREIGN KEY (Code) REFERENCES eucaim_hyperontology_codes.Concept(concept_id)
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


-------------------------------------------------------------------------------------------

-- eucaim_cdm_ingestion.Organization
CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.Organization (
    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    Identifier VARCHAR(50),
    Name VARCHAR(255)
);


-- Cancer Patient, unique identifier. 
-- Min data, age does not go here, BirthDate is NOT required
CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.CancerPatient (
    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    Identifier VARCHAR(150) NOT NULL,
    DatasetIdentifier VARCHAR(150) NOT NULL,
    BirthDate DATE,
	BirthSexCode INTEGER,
    BirthSexEucaim VARCHAR(50),
    BirthSexOriginal VARCHAR(50),
    Ethnicity INTEGER,
	ManagingOrganization VARCHAR(50),
    DiagnosticCategoryCode INTEGER,
    DiagnosticCategoryEucaim VARCHAR(50),
    DiagnosticCategoryOriginal VARCHAR(50),
    Deceased boolean DEFAULT false,
    LastContactDate DATE,
    CauseOfDeath INTEGER,
    processed BOOLEAN DEFAULT FALSE
);


CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.Dataset (
    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
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
    AgeUnitCode INTEGER,
    AgeUnitEUCAIM VARCHAR(50),
    AgeUnitOriginal VARCHAR(50),
    AssertedDate DATE,
	PatientIdentifier VARCHAR(150),
    DatasetIdentifier VARCHAR(150),
	PrimaryCancerConditionCode INTEGER,
    PrimaryCancerConditionEUCAIM VARCHAR(50),
    PrimaryCancerConditionOriginal VARCHAR(50),
	HistologyMorphologyBehaviourCode INTEGER,
    HistologyMorphologyBehaviourEUCAIM VARCHAR(50),
    HistologyMorphologyBehaviourOriginal VARCHAR(50),
	BodySiteCode INTEGER,
    BodySiteEUCAIM VARCHAR(50),
    BodySiteOriginal VARCHAR(50),
	BodySiteLocationQualifierCode INTEGER,
    BodySiteLocationQualifierEUCAIM VARCHAR(50),
    BodySiteLocationQualifierOriginal VARCHAR(50),
	BodySiteLateralityQualifierCode INTEGER,
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
    ValueAsNumber REAL,
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
    Category INTEGER,
    CategoryEUCAIM VARCHAR(50),
    CategoryOriginal VARCHAR(50),
    TumorMarkerCode INTEGER,
    TumorMarkerEUCAIM VARCHAR(50),
    TumorMarkerOriginal VARCHAR(50),
    ValueAsNumber REAL,
    ValueAsConcept INTEGER,
    ValueAsConceptUnit VARCHAR(50),
    DateOfMarker VARCHAR(15),
    processed BOOLEAN DEFAULT FALSE
);


-- Histologic Grade of a Patient, linked through Condition
-- Optionally linked with Procedure
CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.HistologicGrade (
    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	PatientIdentifier VARCHAR(50),
    DatasetIdentifier VARCHAR(150),
	PrimaryCancerIdentifier VARCHAR(50),
    Category INTEGER,
    GradeCode INTEGER,
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
    Subject VARCHAR(50),
    SubjectEUCAIM VARCHAR(50),
    SubjectOriginal VARCHAR(50),
    Relationship VARCHAR(50),
    RelationshipEUCAIM VARCHAR(50),
    RelationshipOriginal VARCHAR(50),
    ConditionCode VARCHAR(50),
    ConditionCodeEUCAIM VARCHAR(50),
    ConditionCodeOriginal VARCHAR(50),
    OnsetAge INTEGER,
    OnsetAgeUnit VARCHAR(50),
    OnsetAgeUnitEUCAIM VARCHAR(50),
    OnsetAgeUnitOriginal VARCHAR(50)
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
	ProcedureCode INTEGER,
    ProcedureEUCAIM VARCHAR(50),
    ProcedureOriginal VARCHAR(150),
    Episode INTEGER,
    EpisodeStartDate VARCHAR(15),
	ProcedureCategoryCode INTEGER,
	DiagnosticValueCode INTEGER,
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
	ImagingProcedureCode INTEGER,
    ImagingProcedureEUCAIM VARCHAR(50),
    ImagingProcedureOriginal VARCHAR(150),
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
	RadiotherapyCode INTEGER,
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
	ProcedureCode INTEGER,
    ProcedureEUCAIM VARCHAR(50),
    ProcedureOriginal VARCHAR(150),
    Episode INTEGER,
    EpisodeStartDate VARCHAR(15),
    processed BOOLEAN DEFAULT FALSE
);


CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.CancerRelatedMedication (
    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    DateOfMedication DATE,
    OffsetFromDiagnosis DECIMAL(5,2),
    OffsetUnitEUCAIM VARCHAR(50),
    OffsetUnitOriginal VARCHAR(50),
	PatientIdentifier VARCHAR(50),
    MedicationCode INTEGER,
    processed BOOLEAN DEFAULT FALSE
);


-- Cancer Stage, linked via Procedure, not directly to Patient
-- Optional link to Condition ?
CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.CancerStage (
    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	ProcedureId INTEGER,
	PrimaryCancerConditionId INTEGER,
	CancerStageCode INTEGER,
	CancerStageMethodCode INTEGER,
	CancerStageValue INTEGER,
    processed BOOLEAN DEFAULT FALSE
);


CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.Episode (
    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	PatientIdentifier VARCHAR(150),
    DatasetIdentifier VARCHAR(150),
	TypeCode INTEGER,
    TypeEUCAIM VARCHAR(50),
    TypeOriginal VARCHAR(50),
	EpisodeNumber INTEGER,
    StartDate VARCHAR(15),
    EndDate VARCHAR(15),
    ParentEpisodeId INTEGER,
    processed BOOLEAN DEFAULT FALSE
);


CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.EpisodeEvent (
    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	EpisodeId INTEGER,
    FOREIGN KEY (EpisodeId) REFERENCES eucaim_cdm_ingestion.Episode(Id),
    EventName INTEGER,
    processed BOOLEAN DEFAULT FALSE
);


CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.ImageStudy (
    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ImageStudyUID VARCHAR(70),
    OffsetFromDiagnosis DECIMAL(5,2),
    OffsetUnit INTEGER,
    ImagingProcedureIdentifier VARCHAR(50),
    ImageStudyCategoryCode INTEGER,
    processed BOOLEAN DEFAULT FALSE
);


CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.ImageSeries (
    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ImageStudyUID VARCHAR(70),
    ImageSeriesUID VARCHAR(70),
    ImageSeriesNumber INTEGER,
    Description VARCHAR(170),
	Manufacturer VARCHAR(70),
    ModalityParameterCode INTEGER,
    ModalityParameterCodeEUCAIM VARCHAR(50),
    ModalityParameterCodeOriginal VARCHAR(50),
    ModalityParameterValueAsCode INTEGER,
    ModalityParameterValueAsCodeEUCAIM VARCHAR(50),
    ModalityParameterValueAsCodeOriginal VARCHAR(50),
    ModalityParameterValueAsNumber DECIMAL(5,2),
    ModalityParameterValueUnit INTEGER,
    ModalityParameterValueUniEUCAIM VARCHAR(50),
    ModalityParameterValueUniOriginal VARCHAR(50),
    processed BOOLEAN DEFAULT FALSE
);


CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.ImageModality (
    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ImageStudyUID VARCHAR(70),
    ImageSeriesUID VARCHAR(70),
    ModalityParameterCode INTEGER,
    ModalityParameterCodeEUCAIM VARCHAR(50),
    ModalityParameterCodeOriginal VARCHAR(50),
    ModalityParameterValueAsCode INTEGER,
    ModalityParameterValueAsCodeEUCAIM VARCHAR(50),
    ModalityParameterValueAsCodeOriginal VARCHAR(50),
    ModalityParameterValueAsNumber DECIMAL(5,2),
    ModalityParameterValueUnit INTEGER,
    ModalityParameterValueUniEUCAIM VARCHAR(50),
    ModalityParameterValueUniOriginal VARCHAR(50),
    processed BOOLEAN DEFAULT FALSE
);


CREATE TABLE IF NOT EXISTS eucaim_cdm_ingestion.ImageTags (
    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
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
    processed BOOLEAN DEFAULT FALSE
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
UNIQUE (imagingprocedureidentifier, imagestudyuid);

ALTER TABLE eucaim_cdm_ingestion.ImageSeries
ADD CONSTRAINT unique_imageseries
UNIQUE (imagestudyuid, imageseriesuid);

ALTER TABLE eucaim_cdm_ingestion.ImageTags
ADD CONSTRAINT unique_imagetags
UNIQUE (imagestudyuid, imageseriesuid, imageseriesidentifier);

ALTER TABLE eucaim_cdm_ingestion.Episode 
ADD CONSTRAINT unique_episode
UNIQUE (patientidentifier, datasetidentifier, typeoriginal, episodenumber, startdate);

----------------------------------------------------
