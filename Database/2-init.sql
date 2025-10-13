-- Step 2 Eucaim CDM Schema definition 

DROP TABLE IF EXISTS CancerStage;
DROP TABLE IF EXISTS PrimaryCancerCondition;
DROP TABLE IF EXISTS EpisodeEvent;
DROP TABLE IF EXISTS Episode;
DROP TABLE IF EXISTS HistologicGrade;
DROP TABLE IF EXISTS EcogPerformanceStatus;
DROP TABLE IF EXISTS HealthStatus;
DROP TABLE IF EXISTS TumorMarkerTest;
DROP TABLE IF EXISTS CancerRelatedProcedure;
DROP TABLE IF EXISTS CancerRelatedMedication;
DROP TABLE IF EXISTS SurgicalProcedure;
DROP TABLE IF EXISTS RadiotherapyCourseSummary;
DROP TABLE IF EXISTS ImageTags;
DROP TABLE IF EXISTS ImageSeries;
DROP TABLE IF EXISTS ImageStudy;
DROP TABLE IF EXISTS ImagingProcedure;
DROP TABLE IF EXISTS CancerPatient;
DROP TABLE IF EXISTS Organization;
DROP TABLE IF EXISTS ValueAsCodeableConcept;
DROP TABLE IF EXISTS Dataset;


-------------------------------------------------------------------------------------------



-- Values of type CodeableConcept, each one will containt atleast the TextValue and hopefully a coded value
CREATE TABLE IF NOT EXISTS ValueAsCodeableConcept (
    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    OriginalTextValue VARCHAR(255),
	Code INTEGER,
    mappingState VARCHAR(50),
    count INTEGER DEFAULT 0,
    FOREIGN KEY (Code) REFERENCES Concept(concept_id)
);



CREATE TABLE IF NOT EXISTS MappedCodeableConceptsResults (
    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    datasetId VARCHAR(50),
    propertyNameOriginal VARCHAR(100),
    propertyNameEUCAIM VARCHAR(100),
    originalValue VARCHAR(50),
    parsedValue VARCHAR(50),
    codeInEUCAIM VARCHAR(50),
    codeCandidatesInEUCAIM VARCHAR(50),
    mappingTimestamp VARCHAR(50),
    processed BOOLEAN DEFAULT FALSE
);


-------------------------------------------------------------------------------------------

-- Organization
CREATE TABLE IF NOT EXISTS Organization (
    Identifier VARCHAR(50) PRIMARY KEY,
    Name VARCHAR(255)
);


-- Cancer Patient, unique identifier. 
-- Min data, age does not go here, BirthDate is NOT required
CREATE TABLE IF NOT EXISTS CancerPatient (
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
    processed BOOLEAN DEFAULT FALSE,
    PRIMARY KEY (Identifier, DatasetIdentifier)
);


CREATE TABLE IF NOT EXISTS Dataset (
    Identifier VARCHAR(150) PRIMARY KEY,
    Title VARCHAR(150),
    Description VARCHAR(500),
    processed BOOLEAN DEFAULT FALSE
);


-- Primary Cancer Condition of a Patient
-- Has either age of diagnosis in years or date of diagnosis
CREATE TABLE IF NOT EXISTS PrimaryCancerCondition (
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


CREATE TABLE IF NOT EXISTS HealthStatus (
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


CREATE TABLE IF NOT EXISTS TumorMarkerTest (
    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    PatientIdentifier VARCHAR(150),
    DatasetIdentifier VARCHAR(150),
    PrimaryCancerIdentifier VARCHAR(50),
    Category INTEGER,
    CategoryEUCAIM VARCHAR(50),
    CategoryOriginal VARCHAR(50),
    TumorMarkerCode INTEGER,
    TumorMarkerEUCAIM VARCHAR(50),
    TumorMarkerOriginal VARCHAR(50),
    ValueAsNumber REAL,
    ValueAsConcept INTEGER,
    ValueAsConceptUnit INTEGER,
    DateOfMarker VARCHAR(15),
    processed BOOLEAN DEFAULT FALSE
);


-- Histologic Grade of a Patient, linked through Condition
-- Optionally linked with Procedure
CREATE TABLE IF NOT EXISTS HistologicGrade (
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


-- Procedure
-- Has either elapsed interval after baseline, in monts, or date of procedure
-- Probably it will be easier to cover at least ProcedureCategoryCode, meant to be a broader concept (i.e. Biopsy) than ProcedureCode (i.e. MRI-US fusion guided prostate biopsy)
CREATE TABLE IF NOT EXISTS CancerRelatedProcedure (
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


CREATE TABLE IF NOT EXISTS ImagingProcedure (
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


CREATE TABLE IF NOT EXISTS RadiotherapyCourseSummary (
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


CREATE TABLE IF NOT EXISTS SurgicalProcedure (
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


CREATE TABLE IF NOT EXISTS CancerRelatedMedication (
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
CREATE TABLE IF NOT EXISTS CancerStage (
    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	ProcedureId INTEGER,
	PrimaryCancerConditionId INTEGER,
	CancerStageCode INTEGER,
	CancerStageMethodCode INTEGER,
	CancerStageValue INTEGER,
    processed BOOLEAN DEFAULT FALSE
);


CREATE TABLE IF NOT EXISTS Episode (
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


CREATE TABLE IF NOT EXISTS EpisodeEvent (
    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	EpisodeId INTEGER,
    FOREIGN KEY (EpisodeId) REFERENCES Episode(Id),
    EventName INTEGER,
    processed BOOLEAN DEFAULT FALSE
);


CREATE TABLE IF NOT EXISTS ImageStudy (
    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ImageStudyUID VARCHAR(70),
    OffsetFromDiagnosis DECIMAL(5,2),
    OffsetUnit INTEGER,
    ImagingProcedureIdentifier VARCHAR(50),
    ImageStudyCategoryCode INTEGER,
    processed BOOLEAN DEFAULT FALSE
);


CREATE TABLE IF NOT EXISTS ImageSeries (
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


CREATE TABLE IF NOT EXISTS ImageModality (
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


CREATE TABLE IF NOT EXISTS ImageTags (
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

ALTER TABLE cancerpatient
ADD CONSTRAINT unique_cancerpatient
UNIQUE (identifier, datasetidentifier);

ALTER TABLE dataset
ADD CONSTRAINT unique_dataset
UNIQUE (identifier);

ALTER TABLE primarycancercondition
ADD CONSTRAINT unique_primarycancercondition
UNIQUE (patientidentifier, datasetidentifier, identifier, episodestartdate);

ALTER TABLE healthstatus
ADD CONSTRAINT unique_healthstatus
UNIQUE (patientidentifier, datasetidentifier, identifier);

ALTER TABLE tumormarkertest
ADD CONSTRAINT unique_tumormarkertest
UNIQUE (patientidentifier, datasetidentifier, primarycanceridentifier, tumormarkeroriginal, dateofmarker);

ALTER TABLE histologicgrade
ADD CONSTRAINT unique_histologicgrade
UNIQUE (patientidentifier, datasetidentifier, primarycanceridentifier);

ALTER TABLE cancerrelatedprocedure
ADD CONSTRAINT unique_cancerrelatedprocedure
UNIQUE (patientidentifier, datasetidentifier, procedureidentifier);

ALTER TABLE imagingprocedure
ADD CONSTRAINT unique_imagingprocedure
UNIQUE (patientidentifier, datasetidentifier, procedureidentifier);

ALTER TABLE radiotherapycoursesummary
ADD CONSTRAINT unique_radiotherapycoursesummary
UNIQUE (patientidentifier, datasetidentifier, procedureidentifier);

ALTER TABLE surgicalprocedure
ADD CONSTRAINT unique_surgicalprocedure
UNIQUE (patientidentifier, datasetidentifier, procedureidentifier);

ALTER TABLE imagestudy
ADD CONSTRAINT unique_imagestudy
UNIQUE (imagingprocedureidentifier, imagestudyuid);

ALTER TABLE imageseries
ADD CONSTRAINT unique_imageseries
UNIQUE (imagestudyuid, imageseriesuid);

ALTER TABLE imagetags
ADD CONSTRAINT unique_imagetags
UNIQUE (imagestudyuid, imageseriesuid, imageseriesidentifier);

ALTER TABLE episode 
ADD CONSTRAINT unique_episode
UNIQUE (patientidentifier, datasetidentifier, typeoriginal, episodenumber, startdate);

----------------------------------------------------
