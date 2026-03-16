----------------------------------------------------
CREATE SCHEMA eucaim_etl_aux;


CREATE TABLE eucaim_etl_aux.LookupHeaderRowsToRemove (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    originalValue VARCHAR(200),

    parsedValue VARCHAR(200)

);



INSERT INTO eucaim_etl_aux.LookupHeaderRowsToRemove (originalValue, parsedValue)

VALUES ('perproglio', '0');



INSERT INTO eucaim_etl_aux.LookupHeaderRowsToRemove (originalValue, parsedValue)

VALUES ('aaaadcw3slp2bbsux2urluqaae', '0');



INSERT INTO eucaim_etl_aux.LookupHeaderRowsToRemove (originalValue, parsedValue)

VALUES ('thyroid', '3');


INSERT INTO eucaim_etl_aux.LookupHeaderRowsToRemove (originalValue, parsedValue)

VALUES ('1181c8428de05bb98fa8896d281cc0fd', '3');


INSERT INTO eucaim_etl_aux.LookupHeaderRowsToRemove (originalValue, parsedValue)

VALUES ('breast', '37');

INSERT INTO eucaim_etl_aux.LookupHeaderRowsToRemove (originalValue, parsedValue)

VALUES ('4fcdd34b95f8eed2a3d07291e4c2173e', '37');


INSERT INTO eucaim_etl_aux.LookupHeaderRowsToRemove (originalValue, parsedValue)

VALUES ('sas', '0');




CREATE TABLE IF NOT EXISTS eucaim_etl_aux.LookupPrimaryCancerConditionCode (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    originalValue VARCHAR(200),

    parsedValue VARCHAR(200)

);





CREATE TABLE IF NOT EXISTS eucaim_etl_aux.LookupRadiotherapyCode (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    originalValue VARCHAR(200),

    parsedValue VARCHAR(200)

);



INSERT INTO eucaim_etl_aux.LookupRadiotherapyCode (originalValue, parsedValue)

VALUES ('external radiotherapy', 'External beam radiation therapy procedure');



CREATE TABLE IF NOT EXISTS eucaim_etl_aux.LookupRadiotherapyModality (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    originalValue VARCHAR(200),

    parsedValue VARCHAR(200)

);





CREATE TABLE IF NOT EXISTS eucaim_etl_aux.LookupRadiotherapyTechnique (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    originalValue VARCHAR(200),

    parsedValue VARCHAR(200)

);





CREATE TABLE IF NOT EXISTS eucaim_etl_aux.LookupProcedureCode (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    originalValue VARCHAR(200),

    parsedValue VARCHAR(200)

);



INSERT INTO eucaim_etl_aux.LookupProcedureCode (originalValue, parsedValue)

VALUES ('Endobronchial Ultrasound-Guided Fine Needle Aspiration (EBUS-FNA)', 'Fine needle biopsy');



INSERT INTO eucaim_etl_aux.LookupProcedureCode (originalValue, parsedValue)

VALUES ('RID10321', 'Computed tomography');



INSERT INTO eucaim_etl_aux.LookupProcedureCode (originalValue, parsedValue)

VALUES ('10318', 'Magnetic resonance imaging');



INSERT INTO eucaim_etl_aux.LookupProcedureCode (originalValue, parsedValue)

VALUES ('RID39574', 'PET-CT');



CREATE TABLE IF NOT EXISTS eucaim_etl_aux.LookupImagingProcedureCode (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    originalValue VARCHAR(200),

    parsedValue VARCHAR(200)

);



INSERT INTO eucaim_etl_aux.LookupImagingProcedureCode (originalValue, parsedValue)

VALUES ('CT', 'Computed tomography');



INSERT INTO eucaim_etl_aux.LookupImagingProcedureCode (originalValue, parsedValue)

VALUES ('RID10321', 'Computed tomography');



INSERT INTO eucaim_etl_aux.LookupImagingProcedureCode (originalValue, parsedValue)

VALUES ('10318', 'Magnetic resonance imaging');



INSERT INTO eucaim_etl_aux.LookupImagingProcedureCode (originalValue, parsedValue)

VALUES ('RID39574', 'PET-CT');



INSERT INTO eucaim_etl_aux.LookupImagingProcedureCode (originalValue, parsedValue)

VALUES ('MG', 'Mammography');




CREATE TABLE IF NOT EXISTS eucaim_etl_aux.LookupHistologyMorphologyCode (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    originalValue VARCHAR(200),

    parsedValue VARCHAR(200)

);



INSERT INTO eucaim_etl_aux.LookupHistologyMorphologyCode (originalValue, parsedValue)

VALUES ('lung squamous cell carcinoma', 'Squamous cell carcinoma, NOS, of lung, NOS');



INSERT INTO eucaim_etl_aux.LookupHistologyMorphologyCode (originalValue, parsedValue)

VALUES ('breast cancer', 'Neoplasm of breast');



INSERT INTO eucaim_etl_aux.LookupHistologyMorphologyCode (originalValue, parsedValue)

VALUES ('thyroid cancer', 'Thyroid cancer');



INSERT INTO eucaim_etl_aux.LookupHistologyMorphologyCode (originalValue, parsedValue)

VALUES ('lung adenocarcinoma', 'Adenocarcinoma, NOS, of lung, NOS');



INSERT INTO eucaim_etl_aux.LookupHistologyMorphologyCode (originalValue, parsedValue)

VALUES ('lung small cell carcinoma', 'Small cell carcinoma of lung, NOS');



CREATE TABLE IF NOT EXISTS eucaim_etl_aux.LookupPatientDiagnosticCategory (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    originalValue VARCHAR(200),

    parsedValue VARCHAR(200)

);

INSERT INTO eucaim_etl_aux.LookupPatientDiagnosticCategory (originalValue, parsedValue)

VALUES ('Patient with Cancer', 'Patient with Cancer');



CREATE TABLE IF NOT EXISTS eucaim_etl_aux.LookupSurgicalProcedureCode (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    originalValue VARCHAR(200),

    parsedValue VARCHAR(200)

);



INSERT INTO eucaim_etl_aux.LookupSurgicalProcedureCode (originalValue, parsedValue)

VALUES ('409063005', 'Excision of malignant neoplasm');



INSERT INTO eucaim_etl_aux.LookupSurgicalProcedureCode (originalValue, parsedValue)

VALUES ('387713004', 'Excision of malignant neoplasm');

INSERT INTO eucaim_etl_aux.LookupSurgicalProcedureCode (originalValue, parsedValue)

VALUES ('sentinel lymph node biopsy', 'Sentinel lymph node biopsy');

CREATE TABLE IF NOT EXISTS eucaim_etl_aux.LookupSurgicalProcedureBodySite (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    originalValue VARCHAR(200),

    parsedValue VARCHAR(200)

);

INSERT INTO eucaim_etl_aux.LookupSurgicalProcedureBodySite (originalValue, parsedValue)

VALUES ('right breast structure', 'Right breast structure');

INSERT INTO eucaim_etl_aux.LookupSurgicalProcedureBodySite (originalValue, parsedValue)

VALUES ('left breast structure', 'Left breast structure');


CREATE TABLE IF NOT EXISTS eucaim_etl_aux.LookupTumorOrganCode (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    originalValue VARCHAR(200),

    parsedValue VARCHAR(200)

);



INSERT INTO eucaim_etl_aux.LookupTumorOrganCode (originalValue, parsedValue)

VALUES ('lung', 'Lung, NOS');



INSERT INTO eucaim_etl_aux.LookupTumorOrganCode (originalValue, parsedValue)

VALUES ('breast', 'Breast');



INSERT INTO eucaim_etl_aux.LookupTumorOrganCode (originalValue, parsedValue)

VALUES ('Thyroid BED', 'Head and neck');





CREATE TABLE IF NOT EXISTS eucaim_etl_aux.LookupTumorSizeDimensionUnit (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    originalValue VARCHAR(200),

    parsedValue VARCHAR(200)

);



INSERT INTO eucaim_etl_aux.LookupTumorSizeDimensionUnit (originalValue, parsedValue)

VALUES ('cm', 'centimeter');



CREATE TABLE IF NOT EXISTS eucaim_etl_aux.LookupTumorLocationCode (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    originalValue VARCHAR(200),

    parsedValue VARCHAR(200)

);



INSERT INTO eucaim_etl_aux.LookupTumorLocationCode (originalValue, parsedValue)

VALUES ('1', 'Frontal brain region');



INSERT INTO eucaim_etl_aux.LookupTumorLocationCode (originalValue, parsedValue)

VALUES ('2', 'Temporal brain region');



INSERT INTO eucaim_etl_aux.LookupTumorLocationCode (originalValue, parsedValue)

VALUES ('4', 'Parietal brain region');



INSERT INTO eucaim_etl_aux.LookupTumorLocationCode (originalValue, parsedValue)

VALUES ('5', 'Occipital bran region');







CREATE TABLE IF NOT EXISTS eucaim_etl_aux.LookupTumorGradeCode (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    originalValue VARCHAR(200),

    parsedValue VARCHAR(200)

);



INSERT INTO eucaim_etl_aux.LookupTumorGradeCode (originalValue, parsedValue)

VALUES ('Grade-1', 'Grade 1 tumor');



INSERT INTO eucaim_etl_aux.LookupTumorGradeCode (originalValue, parsedValue)

VALUES ('Grade-2', 'Grade 2 tumor');



INSERT INTO eucaim_etl_aux.LookupTumorGradeCode (originalValue, parsedValue)

VALUES ('Grade-3', 'Grade 3 tumor');



INSERT INTO eucaim_etl_aux.LookupTumorGradeCode (originalValue, parsedValue)

VALUES ('Grade-4', 'Grade 4 tumor');





CREATE TABLE IF NOT EXISTS eucaim_etl_aux.LookupHealthStatusValueCode (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    originalValue VARCHAR(200),

    parsedValue VARCHAR(200)

);



INSERT INTO eucaim_etl_aux.LookupHealthStatusValueCode (originalValue, parsedValue)

VALUES ('Class I', 'ASA physical status class 1');



INSERT INTO eucaim_etl_aux.LookupHealthStatusValueCode (originalValue, parsedValue)

VALUES ('Class II', 'ASA physical status class 2');



INSERT INTO eucaim_etl_aux.LookupHealthStatusValueCode (originalValue, parsedValue)

VALUES ('Class III', 'ASA physical status class 3');



INSERT INTO eucaim_etl_aux.LookupHealthStatusValueCode (originalValue, parsedValue)

VALUES ('Class IV', 'ASA physical status class 4');



INSERT INTO eucaim_etl_aux.LookupHealthStatusValueCode (originalValue, parsedValue)

VALUES ('Class V', 'ASA physical status class 5');



INSERT INTO eucaim_etl_aux.LookupHealthStatusValueCode (originalValue, parsedValue)

VALUES ('Class VI', 'ASA physical status class 6');



CREATE TABLE IF NOT EXISTS eucaim_etl_aux.LookupFamilyMemberHistoryConditionCode (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    originalValue VARCHAR(200),

    parsedValue VARCHAR(200)

);


INSERT INTO eucaim_etl_aux.LookupFamilyMemberHistoryConditionCode (originalValue, parsedValue)
VALUES ('Breast cancer', 'Carcinoma of breast');

INSERT INTO eucaim_etl_aux.LookupFamilyMemberHistoryConditionCode (originalValue, parsedValue)
VALUES ('Prostate cancer', 'Carcinoma of prostate');

INSERT INTO eucaim_etl_aux.LookupFamilyMemberHistoryConditionCode (originalValue, parsedValue)
VALUES ('Prostate cancer', 'Carcinoma of prostate');




CREATE TABLE IF NOT EXISTS eucaim_etl_aux.LookupTumorMarkerTestCode (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    originalValue VARCHAR(200),
    parsedValue VARCHAR(200)

);

INSERT INTO eucaim_etl_aux.LookupTumorMarkerTestCode (originalValue, parsedValue)
VALUES ('PSA', 'Prostate specific antigen measurement');

INSERT INTO eucaim_etl_aux.LookupTumorMarkerTestCode (originalValue, parsedValue)
VALUES ('ER', 'Presence of estrogen receptor in neoplasm');

INSERT INTO eucaim_etl_aux.LookupTumorMarkerTestCode (originalValue, parsedValue)
VALUES ('PR', 'Presence of progesterone receptor in neoplasm');

INSERT INTO eucaim_etl_aux.LookupTumorMarkerTestCode (originalValue, parsedValue)
VALUES ('KI-67', 'MKI67 (marker of proliferation Ki-67) gene variant measurement');

CREATE TABLE IF NOT EXISTS eucaim_etl_aux.LookupTumorMarkerTest1ResultValueAsConcept (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    originalValue VARCHAR(200),
    parsedValue VARCHAR(200)

);

INSERT INTO eucaim_etl_aux.LookupTumorMarkerTest1ResultValueAsConcept (originalValue, parsedValue)
VALUES ('positive', 'HER2 positive');

INSERT INTO eucaim_etl_aux.LookupTumorMarkerTest1ResultValueAsConcept (originalValue, parsedValue)
VALUES ('negative', 'HER2 negative');

CREATE TABLE IF NOT EXISTS eucaim_etl_aux.LookupTumorMarkerTest2ResultValueAsConcept (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    originalValue VARCHAR(200),
    parsedValue VARCHAR(200)

);

INSERT INTO eucaim_etl_aux.LookupTumorMarkerTest2ResultValueAsConcept (originalValue, parsedValue)
VALUES ('positive', 'ER positive');

INSERT INTO eucaim_etl_aux.LookupTumorMarkerTest2ResultValueAsConcept (originalValue, parsedValue)
VALUES ('negative', 'ER negative');

CREATE TABLE IF NOT EXISTS eucaim_etl_aux.LookupTumorMarkerTest3ResultValueAsConcept (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    originalValue VARCHAR(200),
    parsedValue VARCHAR(200)

);

INSERT INTO eucaim_etl_aux.LookupTumorMarkerTest3ResultValueAsConcept (originalValue, parsedValue)
VALUES ('positive', 'PR positive');

INSERT INTO eucaim_etl_aux.LookupTumorMarkerTest3ResultValueAsConcept (originalValue, parsedValue)
VALUES ('negative', 'PR negative');


CREATE TABLE IF NOT EXISTS eucaim_etl_aux.LookupTumorMarkerTest4ResultValueAsConcept (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    originalValue VARCHAR(200),
    parsedValue VARCHAR(200)

);

INSERT INTO eucaim_etl_aux.LookupTumorMarkerTest4ResultValueAsConcept (originalValue, parsedValue)
VALUES ('positive', 'MKI67 Positive');

INSERT INTO eucaim_etl_aux.LookupTumorMarkerTest4ResultValueAsConcept (originalValue, parsedValue)
VALUES ('negative', 'MKI67 Negative');


CREATE TABLE IF NOT EXISTS eucaim_etl_aux.lookupmedicalhistorycategory (
    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    originalValue VARCHAR(200),
    parsedValue VARCHAR(200)
);

CREATE TABLE IF NOT EXISTS eucaim_etl_aux.LookupMedicalHistoryCode (
    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    originalValue VARCHAR(200),
    parsedValue VARCHAR(200)
);

CREATE TABLE IF NOT EXISTS eucaim_etl_aux.LookupRadiotherapyAdverseEvent (
    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    originalValue VARCHAR(200),
    parsedValue VARCHAR(200)
);

CREATE TABLE IF NOT EXISTS eucaim_etl_aux.LookupRadiotherapyResponse (
    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    originalValue VARCHAR(200),
    parsedValue VARCHAR(200)
);

CREATE TABLE IF NOT EXISTS eucaim_etl_aux.LookupTumorBodySiteCode (
    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    originalValue VARCHAR(200),
    parsedValue VARCHAR(200)
);

INSERT INTO eucaim_etl_aux.LookupTumorBodySiteCode (originalValue, parsedValue)
VALUES ('breast', 'Breast');


CREATE TABLE IF NOT EXISTS eucaim_etl_aux.LookupTumorBodySiteLateralityQualifier (
    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    originalValue VARCHAR(200),
    parsedValue VARCHAR(200)
);

CREATE TABLE IF NOT EXISTS eucaim_etl_aux.LookupTumorBodySiteLocationQualifier (
    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    originalValue VARCHAR(200),
    parsedValue VARCHAR(200)
);

CREATE TABLE IF NOT EXISTS eucaim_etl_aux.LookupTumorGradeCodeService (
    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    originalValue VARCHAR(200),
    parsedValue VARCHAR(200)
);

CREATE TABLE IF NOT EXISTS eucaim_etl_aux.LookupCancerStageValue (
    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    originalValue VARCHAR(200),
    parsedValue VARCHAR(200)
);

CREATE TABLE IF NOT EXISTS eucaim_etl_aux.LookupLabTestResultCode (
    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    originalValue VARCHAR(200),
    parsedValue VARCHAR(200)
);

CREATE TABLE IF NOT EXISTS eucaim_etl_aux.LookupCancerStageCode (
    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    originalValue VARCHAR(200),
    parsedValue VARCHAR(200)
);

CREATE TABLE IF NOT EXISTS eucaim_etl_aux.LookupMedicationAdministrationCode (
    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    originalValue VARCHAR(200),
    parsedValue VARCHAR(200)
);

CREATE TABLE IF NOT EXISTS eucaim_etl_aux.LookupMedicationAdministrationResponse (
    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    originalValue VARCHAR(200),
    parsedValue VARCHAR(200)
);

INSERT INTO eucaim_etl_aux.LookupMedicationAdministrationResponse (originalValue, parsedValue)
VALUES ('partial response', 'Partial response');

INSERT INTO eucaim_etl_aux.LookupMedicationAdministrationResponse (originalValue, parsedValue)
VALUES ('complete response', 'Complete response');

INSERT INTO eucaim_etl_aux.LookupMedicationAdministrationResponse (originalValue, parsedValue)
VALUES ('stable disease', 'Stable disease');

INSERT INTO eucaim_etl_aux.LookupMedicationAdministrationResponse (originalValue, parsedValue)
VALUES ('progressive disease', 'Progressive disease');

CREATE TABLE IF NOT EXISTS eucaim_etl_aux.LookupPrimaryCancerConditionHistologyMorphologyBehavior (
    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    originalValue VARCHAR(200),
    parsedValue VARCHAR(200)
);

INSERT INTO eucaim_etl_aux.LookupPrimaryCancerConditionHistologyMorphologyBehavior (originalValue, parsedValue)
VALUES ('8140', 'Adenocarcinoma, NOS, of prostate gland');

CREATE TABLE IF NOT EXISTS eucaim_etl_aux.LookupPrimaryCancerConditionTopography (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    originalValue VARCHAR(200),
    parsedValue VARCHAR(200)

);

INSERT INTO eucaim_etl_aux.LookupPrimaryCancerConditionHistologyMorphologyBehavior (originalValue, parsedValue)
VALUES ('Malignant neoplasm of the nipple and areola of the right breast', 'Malignant neoplasm: Nipple and areola');

CREATE TABLE IF NOT EXISTS eucaim_etl_aux.LookupImagingModality (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    originalValue VARCHAR(200),
    parsedValue VARCHAR(200)

);




INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('CT', 'IMG1000042');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('MG', 'IMG1004455');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('MR', 'IMG1000038');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('SEG', 'Segmentation');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('PT', 'IMG1000062');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('ST', 'IMG1000061');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('US', 'IMG1000035');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('XA', 'X-Ray Angiography');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('OT', 'Other');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('NM', 'IMG1000071');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('ANN', 'Annotation');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('AS', 'IMG1004462');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('AU', 'Audio');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('STAIN', 'Automated Slide Stainer');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('AR', 'Autorefraction');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('BI', 'Biomagnetic imaging');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('BDUS', 'Bone Densitometry (ultrasound)');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('BMD', 'Bone Densitometry (X-Ray)');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('EPS', 'Cardiac Electrophysiology');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('CF', 'Cinefluorography');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('CD', 'Color flow Doppler');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('CR', 'IMG1000024');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('CFM', 'Confocal Microscopy');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('ASMT', 'Content Assessment Results');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('CTPROTOCOL', 'CT Protocol (Performed)');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('CP', 'Culposcopy');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('CS', 'Cystoscopy');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('DMS', 'Dermoscopy');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('DG', 'Diaphanography');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('DF', 'Digital fluoroscopy');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('DM', 'IMG1004458');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('DX', 'IMG1000028');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('DS', 'Digital Subtraction Angiography');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('DOC', 'Document');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('DD', 'Duplex Doppler');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('EC', 'Echocardiography');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('ECG', 'Electrocardiography');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('EEG', 'Electroencephalography');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('EMG', 'Electromyography');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('EOG', 'Electrooculography');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('ES', 'Endoscopy');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('XC', 'External-camera Photography');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('FID', 'Fiducials');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('FA', 'Fluorescein angiography');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('FS', 'Fundoscopy');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('GM', 'IMG1004457');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('HC', 'Hard Copy');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('HD', 'Hemodynamic Waveform');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('IOL', 'Intraocular Lens Data');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('IO', 'Intra-Oral Radiography');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('IVOCT', 'Intravascular Optical Coherence Tomography');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('IVUS', 'IMG1000035');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('KER', 'Keratometry');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('KO', 'Key Object Selection');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('LP', 'Laparoscopy');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('LS', 'Laser surface scan');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('LEN', 'Lensometry');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('MA', 'IMG1004462');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('MS', 'IMG1000083');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('M3D', 'Model for 3D Manufacturing');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('OAM', 'Ophthalmic Axial Measurements');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('OPM', 'Ophthalmic Mapping');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('OP', 'Ophthalmic Photography');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('OPR', 'Ophthalmic Refraction');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('OPT', 'Ophthalmic Tomography');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('OPTBSV', 'Ophthalmic Tomography B-scan Volume Analysis');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('OPTENF', 'Ophthalmic Tomography En Face');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('OPV', 'Ophthalmic Visual Field');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('OCT', 'Optical Coherence Tomography (non-Ophthalmic)');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('OSS', 'Optical Surface Scan');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('PX', 'Panoramic X-Ray');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('PA', 'Photoacoustic');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('PLAN', 'Plan');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('POS', 'Position Sensor');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('PR', 'Presentation State');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('RF', 'IMG1000041');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('RG', 'Radiographic imaging (conventional film/screen)');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('RTDOSE', 'Radiotherapy Dose');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('RTIMAGE', 'Radiotherapy Image');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('RTINTENT', 'Radiotherapy Intent');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('RTPLAN', 'Radiotherapy Plan');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('RTSEGANN', 'Radiotherapy Segment Annotation');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('RTSTRUCT', 'Radiotherapy Structure Set');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('RWV', 'Real World Value Map');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('REG', 'Registration');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('RESP', 'Respiratory Waveform');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('RTRAD', 'RT Radiation');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('RTRECORD', 'RT Treatment Record');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('SM', 'IMG1004456');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('SR', 'SR Document');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('SMR', 'Stereometric Relationship');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('SRF', 'Subjective Refraction');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('TEXTUREMAP', 'Texture Map');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('TG', 'Thermography');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('VF', 'Videofluorography');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('VA', 'Visual Acuity');

INSERT INTO eucaim_etl_aux.LookupImagingModality (originalValue, parsedValue)

VALUES ('XAPROTOCOL', 'XA Protocol (Performed)');									 




CREATE TABLE IF NOT EXISTS eucaim_etl_aux.LookupBodyPartForImaging (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    originalValue VARCHAR(200),

    parsedValue VARCHAR(200)

);



INSERT INTO eucaim_etl_aux.LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('prostate', 'BP1000021');

INSERT INTO eucaim_etl_aux.LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('brain', 'BP1000051');

INSERT INTO eucaim_etl_aux.LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('heart', 'BP1000075');

INSERT INTO eucaim_etl_aux.LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('gallbladder', 'BP1000142');

INSERT INTO eucaim_etl_aux.LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('bronchus', 'BP1000192');

INSERT INTO eucaim_etl_aux.LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('lung', 'BP1000192');

INSERT INTO eucaim_etl_aux.LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('pancreas', 'BP1000209');

INSERT INTO eucaim_etl_aux.LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('thyroid', 'BP1000286');

INSERT INTO eucaim_etl_aux.LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('cervix uteri', 'BP1000290');

INSERT INTO eucaim_etl_aux.LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('uterus', 'BP1000291');

INSERT INTO eucaim_etl_aux.LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('kidney', 'BP1000298');

INSERT INTO eucaim_etl_aux.LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('vagina', 'BP1000299');

INSERT INTO eucaim_etl_aux.LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('bladder', 'BP1000301');

INSERT INTO eucaim_etl_aux.LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('stomach', 'BP1000302');

INSERT INTO eucaim_etl_aux.LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('esophagus', 'BP1000303');

INSERT INTO eucaim_etl_aux.LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('ovary', 'BP1000340');

INSERT INTO eucaim_etl_aux.LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('colon', 'CLIN1063722');

INSERT INTO eucaim_etl_aux.LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('rectum', 'CLIN1063724');

INSERT INTO eucaim_etl_aux.LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('breast', 'CLIN1063727');




CREATE TABLE IF NOT EXISTS eucaim_etl_aux.LookupManufacturerAlias (

    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    originalValue VARCHAR(200),

    parsedValue VARCHAR(200)

);



INSERT INTO eucaim_etl_aux.LookupManufacturerAlias (originalValue, parsedValue) VALUES ('Siemens Healthineers', 'SIEMENS');

INSERT INTO eucaim_etl_aux.LookupManufacturerAlias (originalValue, parsedValue) VALUES ('Philips Medical Systems', 'PHILIPS');

INSERT INTO eucaim_etl_aux.LookupManufacturerAlias (originalValue, parsedValue) VALUES ('Philips Healthcare', 'PHILIPS');

INSERT INTO eucaim_etl_aux.LookupManufacturerAlias (originalValue, parsedValue) VALUES ('Toshiba Medical', 'TOSHIBA');



----------------------------------------------------

