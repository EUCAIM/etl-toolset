-- Step 3 ETL aux tables 

CREATE TABLE IF NOT EXISTS LookupRadiotherapyCode (
    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    originalValue VARCHAR(200),
    parsedValue VARCHAR(200)
);

INSERT INTO LookupRadiotherapyCode (originalValue, parsedValue)
VALUES ('external radiotherapy', 'External beam radiation therapy procedure');


CREATE TABLE IF NOT EXISTS LookupProcedureCode (
    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    originalValue VARCHAR(200),
    parsedValue VARCHAR(200)
);

INSERT INTO LookupProcedureCode (originalValue, parsedValue)
VALUES ('Endobronchial Ultrasound-Guided Fine Needle Aspiration (EBUS-FNA)', 'Fine needle biopsy');


CREATE TABLE IF NOT EXISTS LookupImagingProcedureCode (
    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    originalValue VARCHAR(200),
    parsedValue VARCHAR(200)
);

INSERT INTO LookupImagingProcedureCode (originalValue, parsedValue)
VALUES ('CT', 'Computed tomography');


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


CREATE TABLE IF NOT EXISTS LookupHeaderRowsToRemove (
    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    originalValue VARCHAR(50),
    parsedValue VARCHAR(3)
);

INSERT INTO LookupHeaderRowsToRemove (originalValue, parsedValue)
VALUES ('perproglio', '0');


----------------------------------------------------