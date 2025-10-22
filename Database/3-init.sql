----------------------------------------------------

CREATE TABLE IF NOT EXISTS LookupPrimaryCancerConditionCode (
    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    originalValue VARCHAR(200),
    parsedValue VARCHAR(200)
);


CREATE TABLE IF NOT EXISTS LookupRadiotherapyCode (
    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    originalValue VARCHAR(200),
    parsedValue VARCHAR(200)
);

INSERT INTO LookupRadiotherapyCode (originalValue, parsedValue)
VALUES ('external radiotherapy', 'External beam radiation therapy procedure');

CREATE TABLE IF NOT EXISTS LookupRadiotherapyModality (
    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    originalValue VARCHAR(200),
    parsedValue VARCHAR(200)
);


CREATE TABLE IF NOT EXISTS LookupRadiotherapyTechnique (
    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    originalValue VARCHAR(200),
    parsedValue VARCHAR(200)
);


CREATE TABLE IF NOT EXISTS LookupProcedureCode (
    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    originalValue VARCHAR(200),
    parsedValue VARCHAR(200)
);

INSERT INTO LookupProcedureCode (originalValue, parsedValue)
VALUES ('Endobronchial Ultrasound-Guided Fine Needle Aspiration (EBUS-FNA)', 'Fine needle biopsy');

INSERT INTO LookupProcedureCode (originalValue, parsedValue)
VALUES ('RID10321', 'Computed tomography');

INSERT INTO LookupProcedureCode (originalValue, parsedValue)
VALUES ('10318', 'Magnetic resonance imaging');

INSERT INTO LookupProcedureCode (originalValue, parsedValue)
VALUES ('RID39574', 'PET-CT');

CREATE TABLE IF NOT EXISTS LookupImagingProcedureCode (
    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    originalValue VARCHAR(200),
    parsedValue VARCHAR(200)
);

INSERT INTO LookupImagingProcedureCode (originalValue, parsedValue)
VALUES ('CT', 'Computed tomography');

INSERT INTO LookupImagingProcedureCode (originalValue, parsedValue)
VALUES ('RID10321', 'Computed tomography');

INSERT INTO LookupImagingProcedureCode (originalValue, parsedValue)
VALUES ('10318', 'Magnetic resonance imaging');

INSERT INTO LookupImagingProcedureCode (originalValue, parsedValue)
VALUES ('RID39574', 'PET-CT');


CREATE TABLE IF NOT EXISTS LookupHistologyMorphologyCode (
    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    originalValue VARCHAR(200),
    parsedValue VARCHAR(200)
);

INSERT INTO LookupHistologyMorphologyCode (originalValue, parsedValue)
VALUES ('lung squamous cell carcinoma', 'Squamous cell carcinoma, NOS, of lung, NOS');

INSERT INTO LookupHistologyMorphologyCode (originalValue, parsedValue)
VALUES ('breast cancer', 'Neoplasm of breast');

INSERT INTO LookupHistologyMorphologyCode (originalValue, parsedValue)
VALUES ('thyroid cancer', 'Thyroid cancer');

INSERT INTO LookupHistologyMorphologyCode (originalValue, parsedValue)
VALUES ('lung adenocarcinoma', 'Adenocarcinoma, NOS, of lung, NOS');

INSERT INTO LookupHistologyMorphologyCode (originalValue, parsedValue)
VALUES ('lung small cell carcinoma', 'Small cell carcinoma of lung, NOS');

CREATE TABLE IF NOT EXISTS LookupPatientDiagnosticCategory (
    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    originalValue VARCHAR(200),
    parsedValue VARCHAR(200)
);
INSERT INTO LookupPatientDiagnosticCategory (originalValue, parsedValue)
VALUES ('Patient with Cancer', 'Patient with Cancer');

CREATE TABLE IF NOT EXISTS LookupSurgicalProcedureCode (
    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    originalValue VARCHAR(200),
    parsedValue VARCHAR(200)
);

INSERT INTO LookupSurgicalProcedureCode (originalValue, parsedValue)
VALUES ('409063005', 'Excision of malignant neoplasm');

INSERT INTO LookupSurgicalProcedureCode (originalValue, parsedValue)
VALUES ('387713004', 'Excision of malignant neoplasm');

CREATE TABLE IF NOT EXISTS LookupTumorOrganCode (
    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    originalValue VARCHAR(200),
    parsedValue VARCHAR(200)
);

INSERT INTO LookupTumorOrganCode (originalValue, parsedValue)
VALUES ('lung', 'Lung, NOS');

INSERT INTO LookupTumorOrganCode (originalValue, parsedValue)
VALUES ('breast', 'Breast');

INSERT INTO LookupTumorOrganCode (originalValue, parsedValue)
VALUES ('Thyroid BED', 'Head and neck');


CREATE TABLE IF NOT EXISTS LookupTumorSizeDimensionUnit (
    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    originalValue VARCHAR(200),
    parsedValue VARCHAR(200)
);

INSERT INTO LookupTumorSizeDimensionUnit (originalValue, parsedValue)
VALUES ('cm', 'centimeter');

CREATE TABLE IF NOT EXISTS LookupTumorLocationCode (
    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    originalValue VARCHAR(200),
    parsedValue VARCHAR(200)
);

INSERT INTO LookupTumorLocationCode (originalValue, parsedValue)
VALUES ('1', 'Frontal brain region');

INSERT INTO LookupTumorLocationCode (originalValue, parsedValue)
VALUES ('2', 'Temporal brain region');

INSERT INTO LookupTumorLocationCode (originalValue, parsedValue)
VALUES ('4', 'Parietal brain region');

INSERT INTO LookupTumorLocationCode (originalValue, parsedValue)
VALUES ('5', 'Occipital bran region');



CREATE TABLE IF NOT EXISTS LookupTumorGradeCode (
    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    originalValue VARCHAR(200),
    parsedValue VARCHAR(200)
);

INSERT INTO LookupTumorGradeCode (originalValue, parsedValue)
VALUES ('Grade-1', 'Grade 1 tumor');

INSERT INTO LookupTumorGradeCode (originalValue, parsedValue)
VALUES ('Grade-2', 'Grade 2 tumor');

INSERT INTO LookupTumorGradeCode (originalValue, parsedValue)
VALUES ('Grade-3', 'Grade 3 tumor');

INSERT INTO LookupTumorGradeCode (originalValue, parsedValue)
VALUES ('Grade-4', 'Grade 4 tumor');


CREATE TABLE IF NOT EXISTS LookupHealthStatusValueCode (
    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    originalValue VARCHAR(200),
    parsedValue VARCHAR(200)
);

INSERT INTO LookupHealthStatusValueCode (originalValue, parsedValue)
VALUES ('Class I', 'ASA physical status class 1');

INSERT INTO LookupHealthStatusValueCode (originalValue, parsedValue)
VALUES ('Class II', 'ASA physical status class 2');

INSERT INTO LookupHealthStatusValueCode (originalValue, parsedValue)
VALUES ('Class III', 'ASA physical status class 3');

INSERT INTO LookupHealthStatusValueCode (originalValue, parsedValue)
VALUES ('Class IV', 'ASA physical status class 4');

INSERT INTO LookupHealthStatusValueCode (originalValue, parsedValue)
VALUES ('Class V', 'ASA physical status class 5');

INSERT INTO LookupHealthStatusValueCode (originalValue, parsedValue)
VALUES ('Class VI', 'ASA physical status class 6');

CREATE TABLE IF NOT EXISTS LookupFamilyMemberHistoryConditionCode (
    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    originalValue VARCHAR(200),
    parsedValue VARCHAR(200)
);

INSERT INTO LookupFamilyMemberHistoryConditionCode (originalValue, parsedValue)
VALUES ('Breast cancer', 'Carcinoma of breast');

INSERT INTO LookupFamilyMemberHistoryConditionCode (originalValue, parsedValue)
VALUES ('Prostate cancer', 'Carcinoma of prostate');

CREATE TABLE IF NOT EXISTS LookupTumorMarkerTestCode (
    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    originalValue VARCHAR(200),
    parsedValue VARCHAR(200)
);

INSERT INTO LookupTumorMarkerTestCode (originalValue, parsedValue)
VALUES ('PSA', 'Prostate specific antigen measurement');

CREATE TABLE LookupHeaderRowsToRemove (
     Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
     originalValue VARCHAR(200),
    parsedValue VARCHAR(200)
);

INSERT INTO LookupHeaderRowsToRemove (originalValue, parsedValue)
VALUES ('perproglio', '0');

INSERT INTO LookupHeaderRowsToRemove (originalValue, parsedValue)
VALUES ('aaaadcw3slp2bbsux2urluqaae', '0');

----------------------------------------------------
