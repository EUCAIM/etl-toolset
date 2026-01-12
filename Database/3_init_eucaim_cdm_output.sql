-- Step 3 Eucaim CDM Schema definition: output

CREATE SCHEMA eucaim_cdm_output;



-- Dataset & CancerPatient
CREATE TABLE IF NOT EXISTS eucaim_cdm_output.Dataset (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    Identifier VARCHAR(150),

    Title VARCHAR(150),

    Description VARCHAR(500)
);


CREATE TABLE IF NOT EXISTS eucaim_cdm_output.CancerPatient (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    Identifier VARCHAR(150) NOT NULL,

    DatasetId INTEGER REFERENCES eucaim_cdm_output.Dataset(id) ON DELETE CASCADE,

    BirthDate DATE,

    BirthSexCode VARCHAR(50),

    Ethnicity VARCHAR(50),

	ManagingOrganization VARCHAR(50),

    DiagnosticCategoryCode VARCHAR(50),

    Deceased boolean DEFAULT false,

    LastContactDate DATE,

    CauseOfDeath INTEGER
);


-- Entities related with CancerPatient directly: HealthStatus, TumorMarkerTest, FamilyMemberHistory
CREATE TABLE IF NOT EXISTS eucaim_cdm_output.HealthStatus (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    PatientId INTEGER REFERENCES eucaim_cdm_output.CancerPatient(id) ON DELETE CASCADE,

    HealthStatusCode VARCHAR(50),

    ValueAsNumber DECIMAL(5,2),

    ValueAsConcept VARCHAR(50),

    ValueAsConceptUnit VARCHAR(50),

    processed BOOLEAN DEFAULT FALSE

);


CREATE TABLE IF NOT EXISTS eucaim_cdm_output.TumorMarkerTest (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    PatientId INTEGER REFERENCES eucaim_cdm_output.CancerPatient(id) ON DELETE CASCADE,

    Category VARCHAR(50),

    TumorMarkerCode VARCHAR(50),

    ValueAsNumber REAL,

    ValueAsConcept VARCHAR(50),

    ValueAsConceptUnit VARCHAR(50),

    DateOfMarker VARCHAR(15)
);


CREATE TABLE IF NOT EXISTS eucaim_cdm_output.FamilyMemberHistory (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    PatientId INTEGER REFERENCES eucaim_cdm_output.CancerPatient(id) ON DELETE CASCADE,

    Subject VARCHAR(50),

    Relationship VARCHAR(50),

    ConditionCode VARCHAR(50),

    OnsetAge INTEGER,

    OnsetAgeUnit VARCHAR(50)
);


-- Treatments: SurgicalProcedure, MedicationAdministration, Radiotherapy
CREATE TABLE IF NOT EXISTS eucaim_cdm_output.RadiotherapyCourseSummary (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    PatientId INTEGER REFERENCES eucaim_cdm_output.CancerPatient(id) ON DELETE CASCADE,

    OffsetFromDiagnosis DECIMAL(5,2),

    OffsetUnit VARCHAR(50),

    PerformedDate VARCHAR(15),

    Episode INTEGER,

    EpisodeStartDate VARCHAR(15),

	RadiotherapyCode VARCHAR(50)
);


CREATE TABLE IF NOT EXISTS eucaim_cdm_output.SurgicalProcedure (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    PatientId INTEGER REFERENCES eucaim_cdm_output.CancerPatient(id) ON DELETE CASCADE,

    OffsetFromDiagnosis DECIMAL(5,2),

    OffsetUnit VARCHAR(50),

    PerformedDate VARCHAR(15),

	ProcedureCode VARCHAR(50),

    Episode INTEGER,

    EpisodeStartDate VARCHAR(15)
);


CREATE TABLE IF NOT EXISTS eucaim_cdm_output.CancerRelatedMedication (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    PatientId INTEGER REFERENCES eucaim_cdm_output.CancerPatient(id) ON DELETE CASCADE,

    DateOfMedication DATE,

    OffsetFromDiagnosis DECIMAL(5,2),

    OffsetUnit VARCHAR(50),

    MedicationCode VARCHAR(50)
);


-- PrimaryCancerCondition, HistologicGrade, CancerStage, Procedure, ImagingProcedure, Tumor
CREATE TABLE IF NOT EXISTS eucaim_cdm_output.PrimaryCancerCondition (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    PatientId INTEGER REFERENCES eucaim_cdm_output.CancerPatient(id) ON DELETE CASCADE,

    Identifier VARCHAR(150),

    AgeOfDiagnosis DECIMAL(5,2),

    AgeUnitCode VARCHAR(50),

    AssertedDate DATE,

    PrimaryCancerConditionCode VARCHAR(50),

    HistologyMorphologyBehaviourCode VARCHAR(50),

    BodySiteCode VARCHAR(50),

    BodySiteLocationQualifierCode VARCHAR(50),

    BodySiteLateralityQualifierCode VARCHAR(50),

    EpisodeNumber INTEGER,

    EpisodeStartDate DATE,

    ConfirmedByProcedure VARCHAR(150)
);


CREATE TABLE IF NOT EXISTS eucaim_cdm_output.HistologicGrade (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

	PrimaryCancerConditionId INTEGER REFERENCES eucaim_cdm_output.PrimaryCancerCondition(id) ON DELETE CASCADE,

    Category VARCHAR(50),

    GradeCode VARCHAR(50)
);


CREATE TABLE IF NOT EXISTS eucaim_cdm_output.CancerStage (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

	PrimaryCancerConditionId INTEGER REFERENCES eucaim_cdm_output.PrimaryCancerCondition(id) ON DELETE CASCADE,

	CancerStageCode VARCHAR(50),

	CancerStageMethodCode VARCHAR(50),

	CancerStageValue VARCHAR(50)
);


CREATE TABLE IF NOT EXISTS eucaim_cdm_output.CancerRelatedProcedure (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    PrimaryCancerConditionId INTEGER REFERENCES eucaim_cdm_output.PrimaryCancerCondition(id) ON DELETE CASCADE,

    ProcedureIdentifier VARCHAR(150),

    OffsetFromDiagnosis DECIMAL(5,2),

    OffsetUnit VARCHAR(50),

    PerformedDate VARCHAR(15),

	ProcedureCode VARCHAR(50),

    ProcedureCategoryCode VARCHAR(50),

    Episode INTEGER,

	DiagnosticValueCode VARCHAR(50)
);


CREATE TABLE IF NOT EXISTS eucaim_cdm_output.ImagingProcedure (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    PrimaryCancerConditionId INTEGER REFERENCES eucaim_cdm_output.PrimaryCancerCondition(id) ON DELETE CASCADE,

    ProcedureIdentifier VARCHAR(150),

    OffsetFromDiagnosis DECIMAL(5,2),

    OffsetUnit VARCHAR(50),

    PerformedDate VARCHAR(15),

	ImagingProcedureCode VARCHAR(50),

    ImagingProcedureCategoryCode VARCHAR(50),

    ImagingTimepoint INTEGER,

    Episode INTEGER,

    DiagnosticValueCode VARCHAR(50)
);


CREATE TABLE IF NOT EXISTS eucaim_cdm_output.Tumor (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    PrimaryCancerConditionId INTEGER REFERENCES eucaim_cdm_output.PrimaryCancerCondition(id) ON DELETE CASCADE,

    Identifier VARCHAR(150),

	isIndex BOOLEAN,

	morphology VARCHAR(50),

	volume DECIMAL(5,2),

	sizeMethod VARCHAR(50),

	sizeMaximumDimension DECIMAL(5,2),

	sizeOtherDimension DECIMAL(5,2),

	sizeDimensionUnit VARCHAR (15),

    BodySite VARCHAR(50),

    BodySiteLocationQualifier VARCHAR(50),

    BodySiteLateralityQualifier VARCHAR(50)
);


-- Entities related with Tumor directly: RiskAssessment, TumorObservation
CREATE TABLE IF NOT EXISTS eucaim_cdm_output.RiskAssessment (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    TumorId INTEGER REFERENCES eucaim_cdm_output.Tumor(id) ON DELETE CASCADE,

	code VARCHAR(150),

	valueUnit VARCHAR (15),

    valueAsConcept VARCHAR(50),

    ValueAsNumber Integer
);


CREATE TABLE IF NOT EXISTS eucaim_cdm_output.TumorObservation (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

	TumorId INTEGER REFERENCES eucaim_cdm_output.Tumor(id) ON DELETE CASCADE,

	code VARCHAR(150),

	valueUnit VARCHAR (15),

    valueAsConcept VARCHAR(50),

    ValueAsNumber Integer
);


-- Episode & EpisodeEvent
CREATE TABLE IF NOT EXISTS eucaim_cdm_output.Episode (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    DatasetId INTEGER,

	TypeCode INTEGER,

	EpisodeNumber INTEGER,

    StartDate VARCHAR(15),

    EndDate VARCHAR(15),

    ParentEpisodeId INTEGER
);


CREATE TABLE IF NOT EXISTS eucaim_cdm_output.EpisodeEvent (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

	EpisodeId INTEGER,

    EntityEventName INTEGER
);


-- Entities for DICOM metadata
CREATE TABLE IF NOT EXISTS eucaim_cdm_output.ImageStudy (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    ImagingProcedureId INTEGER REFERENCES eucaim_cdm_output.ImagingProcedure(id) ON DELETE CASCADE,

    ImageStudyUID VARCHAR(70),

    ImagingTimepoint INTEGER,

    OffsetFromDiagnosis DECIMAL(5,2),

    OffsetUnit VARCHAR(20),

    ImageStudyCategoryCode VARCHAR(70)
);


CREATE TABLE IF NOT EXISTS eucaim_cdm_output.ImageSeries (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    ImageStudyID INTEGER REFERENCES eucaim_cdm_output.ImageStudy(id) ON DELETE CASCADE,

    ImageSeriesUID VARCHAR(70),

    ImageSeriesNumber INTEGER,

    Description VARCHAR(170),

	Manufacturer VARCHAR(70)

);


CREATE TABLE IF NOT EXISTS eucaim_cdm_output.ImageModality (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    ImageSeriesID INTEGER REFERENCES eucaim_cdm_output.ImageSeries(id) ON DELETE CASCADE,

    ModalityParameterCodeEUCAIM VARCHAR(50),

    ModalityParameterCodeOriginal VARCHAR(50),

    ModalityParameterValueAsCodeEUCAIM VARCHAR(50),

    ModalityParameterValueAsCodeOriginal VARCHAR(50),

    ModalityParameterValueAsNumber DECIMAL(5,2),

    ModalityParameterValueUnitEUCAIM VARCHAR(50),

    ModalityParameterValueUnitOriginal VARCHAR(50)
    
);