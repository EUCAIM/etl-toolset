-- Step 3 Eucaim CDM Schema definition: output

CREATE SCHEMA eucaim_cdm_output;




CREATE TABLE IF NOT EXISTS eucaim_cdm_output.Dataset (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    Identifier VARCHAR(150),

    Title VARCHAR(150),

    Description VARCHAR(500)
);


CREATE TABLE IF NOT EXISTS eucaim_cdm_output.CancerPatient (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    Identifier VARCHAR(150) NOT NULL,

    DatasetId INTEGER REFERENCES eucaim_cdm_output.Dataset(id),

    BirthDate DATE,

    BirthSexCode VARCHAR(50),

    Ethnicity INTEGER,

	ManagingOrganization VARCHAR(50),

    DiagnosticCategoryCode VARCHAR(50),

    Deceased boolean DEFAULT false,

    LastContactDate DATE,

    CauseOfDeath INTEGER
);


CREATE TABLE IF NOT EXISTS eucaim_cdm_output.PrimaryCancerCondition (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    PatientId INTEGER REFERENCES eucaim_cdm_output.CancerPatient(id),

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



CREATE TABLE IF NOT EXISTS eucaim_cdm_output.FamilyMemberHistory (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    PatientId INTEGER REFERENCES eucaim_cdm_output.CancerPatient(id),

    FamiliMemberIdentifier VARCHAR(150),

    Subject VARCHAR(50),

    Relationship VARCHAR(50),

    ConditionCode VARCHAR(50),

    OnsetAge INTEGER,

    OnsetAgeUnit VARCHAR(50)
);


CREATE TABLE IF NOT EXISTS eucaim_cdm_output.CancerRelatedProcedure (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    PatientId INTEGER REFERENCES eucaim_cdm_output.CancerPatient(id),

    ProcedureIdentifier VARCHAR(150),

    OffsetFromDiagnosis DECIMAL(5,2),

    OffsetUnitEUCAIM VARCHAR(50),

    OffsetUnitOriginal VARCHAR(50),

    PerformedDate VARCHAR(15),

	ProcedureCode INTEGER,

    Episode INTEGER,

	ProcedureCategoryCode INTEGER,

	DiagnosticValueCode INTEGER
);


CREATE TABLE IF NOT EXISTS eucaim_cdm_output.ImagingProcedure (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    PatientId INTEGER REFERENCES eucaim_cdm_output.CancerPatient(id),

    ProcedureIdentifier VARCHAR(150),

    OffsetFromDiagnosis DECIMAL(5,2),

    OffsetUnit INTEGER,

    PerformedDate VARCHAR(15),

	ImagingProcedureCode INTEGER,

    ImagingProcedureCategoryCode INTEGER,

    ImagingTimepoint INTEGER,

    Episode INTEGER
);


CREATE TABLE IF NOT EXISTS eucaim_cdm_output.RadiotherapyCourseSummary (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    PatientId INTEGER REFERENCES eucaim_cdm_output.CancerPatient(id),

    ProcedureIdentifier VARCHAR(150),

    OffsetFromDiagnosis DECIMAL(5,2),

    OffsetUnitEUCAIM VARCHAR(50),

    OffsetUnitOriginal VARCHAR(50),

    PerformedDate VARCHAR(15),

    Episode INTEGER,

    EpisodeStartDate VARCHAR(15),

	RadiotherapyCode INTEGER
);


CREATE TABLE IF NOT EXISTS eucaim_cdm_output.SurgicalProcedure (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    PatientId INTEGER REFERENCES eucaim_cdm_output.CancerPatient(id),

    ProcedureIdentifier VARCHAR(150),

    OffsetFromDiagnosis DECIMAL(5,2),

    OffsetUnitEUCAIM VARCHAR(50),

    OffsetUnitOriginal VARCHAR(50),

    PerformedDate VARCHAR(15),

	ProcedureCode INTEGER,

    Episode INTEGER,

    EpisodeStartDate VARCHAR(15)
);


CREATE TABLE IF NOT EXISTS eucaim_cdm_output.CancerRelatedMedication (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    PatientId INTEGER REFERENCES eucaim_cdm_output.CancerPatient(id),

    DateOfMedication DATE,

    OffsetFromDiagnosis DECIMAL(5,2),

    OffsetUnit INTEGER,

    MedicationCode INTEGER
);



CREATE TABLE IF NOT EXISTS eucaim_cdm_output.TumorMarkerTest (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    PatientId INTEGER REFERENCES eucaim_cdm_output.CancerPatient(id),

    PrimaryCancerIdentifier VARCHAR(150),

    Category VARCHAR(50),

    TumorMarkerCode VARCHAR(50),

    ValueAsNumber REAL,

    ValueAsConcept INTEGER,

    ValueAsConceptUnit VARCHAR(50),

    DateOfMarker VARCHAR(15)
);


CREATE TABLE IF NOT EXISTS eucaim_cdm_output.Tumor (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    PrimaryCancerConditionId INTEGER REFERENCES eucaim_cdm_output.PrimaryCancerCondition(id),

	isIndex BOOLEAN,

	morphology INTEGER,

	volume INTEGER,

	sizeMethod INTEGER,

	sizeMaximumDimension INTEGER,

	sizeOhterDimension INTEGER,

	sizeDimensionUnit VARCHAR (15),

    BodySiteEUCAIM VARCHAR(50),

    BodySiteOriginal VARCHAR(50),

    BodySiteLocationQualifier INTEGER,

    BodySiteLateralityQualifier INTEGER,

	HistologicGradeEUCAIM VARCHAR(50),

    HistologicGradeOriginal VARCHAR(50),

    HistologicGradeValue INTEGER
);


CREATE TABLE IF NOT EXISTS eucaim_cdm_output.RiskAssessment (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    PrimaryCancerConditionId INTEGER REFERENCES eucaim_cdm_output.PrimaryCancerCondition(id) ,

	code VARCHAR(150),

	valueUnit VARCHAR (15),

    valueAsConcept VARCHAR(50),

    ValueAsNumber Integer
);


CREATE TABLE IF NOT EXISTS eucaim_cdm_output.TumorObservation (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

	PrimaryCancerConditionId INTEGER REFERENCES eucaim_cdm_output.PrimaryCancerCondition(id),

	code VARCHAR(150),

	valueUnit VARCHAR (15),

    valueAsConcept VARCHAR(50),

    ValueAsNumber Integer
);


CREATE TABLE IF NOT EXISTS eucaim_cdm_output.HistologicGrade (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

	PrimaryCancerConditionId INTEGER REFERENCES eucaim_cdm_output.PrimaryCancerCondition(id),

    Category INTEGER,

    GradeCode INTEGER,

    Value INTEGER
);





CREATE TABLE IF NOT EXISTS eucaim_cdm_output.CancerStage (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

	PrimaryCancerConditionId INTEGER REFERENCES eucaim_cdm_output.PrimaryCancerCondition(id),

	CancerStageCode INTEGER,

	CancerStageMethodCode INTEGER,

	CancerStageValue INTEGER
);


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


CREATE TABLE IF NOT EXISTS eucaim_cdm_output.ImageStudy (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    ImagingProcedureId INTEGER REFERENCES eucaim_cdm_output.ImagingProcedure(id),

    ImageStudyUID VARCHAR(70),

    ImagingTimepoint INTEGER,

    OffsetFromDiagnosis DECIMAL(5,2),

    OffsetUnit INTEGER,

    ImageStudyCategoryCode INTEGER
);


CREATE TABLE IF NOT EXISTS eucaim_cdm_output.ImageSeries (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    ImageStudyID INTEGER REFERENCES eucaim_cdm_output.ImageStudy(id),

    ImageSeriesUID VARCHAR(70),

    ImageSeriesNumber INTEGER,

    Description VARCHAR(170),

	Manufacturer VARCHAR(70),

    ModalityParameterCode INTEGER,

    ModalityParameterValueAsCode INTEGER,

    ModalityParameterValueAsNumber DECIMAL(5,2),

    ModalityParameterValueUnit INTEGER
);


CREATE TABLE IF NOT EXISTS eucaim_cdm_output.ImageModality (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    ImageStudyID INTEGER REFERENCES eucaim_cdm_output.ImageStudy(id),

    ImageSeriesUID VARCHAR(70),

    ModalityParameterCode INTEGER,

    ModalityParameterValueAsCode INTEGER,

    ModalityParameterValueAsNumber DECIMAL(5,2),

    ModalityParameterValueUnit INTEGER
);


CREATE TABLE IF NOT EXISTS eucaim_cdm_output.ImageTags (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    ImageSeriesIdentifier INTEGER,

    ImageSeriesID INTEGER REFERENCES eucaim_cdm_output.ImageSeries(id),

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

    ConvolutionKernel VARCHAR(30)
);