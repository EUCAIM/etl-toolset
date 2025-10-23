----------------------------------------------------

CREATE TABLE LookupHeaderRowsToRemove (
	Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    originalValue VARCHAR(200),
    parsedValue VARCHAR(200)
);

INSERT INTO LookupHeaderRowsToRemove (originalValue, parsedValue)
VALUES ('perproglio', '0');

INSERT INTO LookupHeaderRowsToRemove (originalValue, parsedValue)
VALUES ('aaaadcw3slp2bbsux2urluqaae', '0');

INSERT INTO LookupHeaderRowsToRemove (originalValue, parsedValue)
VALUES ('thyroid', '3');

INSERT INTO LookupHeaderRowsToRemove (originalValue, parsedValue)
VALUES ('breast', '37');
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
CREATE TABLE IF NOT EXISTS LookupImagingModality (
    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    originalValue VARCHAR(200),
    parsedValue VARCHAR(200)
);

INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('CT', 'Computed Tomography');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('MG', 'Mammography');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('MR', 'Magnetic Resonance');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('SEG', 'Segmentation');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('PT', 'Positron emission tomography (PET)');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('ST', 'Single-photon emission computed tomography (SPECT)');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('US', 'Ultrasound');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('XA', 'X-Ray Angiography');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('OT', 'Other');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('NM', 'Nuclear Medicine');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('ANN', 'Annotation');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('AS', 'Angioscopy');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('AU', 'Audio');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('STAIN', 'Automated Slide Stainer');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('AR', 'Autorefraction');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('BI', 'Biomagnetic imaging');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('BDUS', 'Bone Densitometry (ultrasound)');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('BMD', 'Bone Densitometry (X-Ray)');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('EPS', 'Cardiac Electrophysiology');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('CF', 'Cinefluorography');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('CD', 'Color flow Doppler');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('CR', 'Computed Radiography');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('CFM', 'Confocal Microscopy');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('ASMT', 'Content Assessment Results');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('CTPROTOCOL', 'CT Protocol (Performed)');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('CP', 'Culposcopy');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('CS', 'Cystoscopy');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('DMS', 'Dermoscopy');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('DG', 'Diaphanography');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('DF', 'Digital fluoroscopy');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('DM', 'Digital microscopy');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('DX', 'Digital Radiography');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('DS', 'Digital Subtraction Angiography');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('DOC', 'Document');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('DD', 'Duplex Doppler');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('EC', 'Echocardiography');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('ECG', 'Electrocardiography');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('EEG', 'Electroencephalography');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('EMG', 'Electromyography');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('EOG', 'Electrooculography');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('ES', 'Endoscopy');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('XC', 'External-camera Photography');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('FID', 'Fiducials');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('FA', 'Fluorescein angiography');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('FS', 'Fundoscopy');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('GM', 'General Microscopy');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('HC', 'Hard Copy');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('HD', 'Hemodynamic Waveform');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('IOL', 'Intraocular Lens Data');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('IO', 'Intra-Oral Radiography');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('IVOCT', 'Intravascular Optical Coherence Tomography');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('IVUS', 'Intravascular Ultrasound');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('KER', 'Keratometry');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('KO', 'Key Object Selection');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('LP', 'Laparoscopy');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('LS', 'Laser surface scan');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('LEN', 'Lensometry');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('MA', 'Magnetic resonance angiography');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('MS', 'Magnetic resonance spectroscopy');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('M3D', 'Model for 3D Manufacturing');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('OAM', 'Ophthalmic Axial Measurements');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('OPM', 'Ophthalmic Mapping');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('OP', 'Ophthalmic Photography');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('OPR', 'Ophthalmic Refraction');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('OPT', 'Ophthalmic Tomography');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('OPTBSV', 'Ophthalmic Tomography B-scan Volume Analysis');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('OPTENF', 'Ophthalmic Tomography En Face');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('OPV', 'Ophthalmic Visual Field');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('OCT', 'Optical Coherence Tomography (non-Ophthalmic)');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('OSS', 'Optical Surface Scan');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('PX', 'Panoramic X-Ray');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('PA', 'Photoacoustic');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('PLAN', 'Plan');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('POS', 'Position Sensor');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('PR', 'Presentation State');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('RF', 'Radio Fluoroscopy');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('RG', 'Radiographic imaging (conventional film/screen)');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('RTDOSE', 'Radiotherapy Dose');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('RTIMAGE', 'Radiotherapy Image');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('RTINTENT', 'Radiotherapy Intent');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('RTPLAN', 'Radiotherapy Plan');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('RTSEGANN', 'Radiotherapy Segment Annotation');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('RTSTRUCT', 'Radiotherapy Structure Set');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('RWV', 'Real World Value Map');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('REG', 'Registration');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('RESP', 'Respiratory Waveform');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('RTRAD', 'RT Radiation');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('RTRECORD', 'RT Treatment Record');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('SM', 'Slide Microscopy');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('SR', 'SR Document');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('SMR', 'Stereometric Relationship');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('SRF', 'Subjective Refraction');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('TEXTUREMAP', 'Texture Map');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('TG', 'Thermography');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('VF', 'Videofluorography');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('VA', 'Visual Acuity');
INSERT INTO LookupImagingModality (originalValue, parsedValue)
VALUES ('XAPROTOCOL', 'XA Protocol (Performed)');									 



CREATE TABLE IF NOT EXISTS LookupTumorMarkerTestCode (
    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    originalValue VARCHAR(200),
    parsedValue VARCHAR(200)
);

INSERT INTO LookupTumorMarkerTestCode (originalValue, parsedValue)
VALUES ('PSA', 'Prostate specific antigen measurement');
CREATE TABLE IF NOT EXISTS LookupBodyPartForImaging (
    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    originalValue VARCHAR(200),
    parsedValue VARCHAR(200)
);

INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('ABDOMEN', '818981001');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('ABDOMENPELVIS', '818982008');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('BLADDER', '89837001');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('BRAIN', '12738006');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('BREAST', '76752008');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('CHEST', '43799004');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('CHESTABDOMEN', '416550000');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('CHESTABDPELVIS', '416775004');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('COLON', '71854001');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('HEAD', '69536005');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('HEADNECK', '774007');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('LIVER', '10200004');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('LUNG', '39607008');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('OVARY', '15497006');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('PANCREAS', '15776009');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('PELVIS', '816092008');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('PELVISLOWEXTREMT', '1231522001');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('PROSTATE', '41216001');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('RECTUM', '34402009');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('SPINE', '421060004');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('THYROID', '69748006');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('UTERUS', '35039007');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('3RDVENTRICLE', '49841001');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('4THVENTRICLE', '35918002');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('ABDOMINALAORTA', '7832008');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('ACA', '60176003');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('ACJOINT', '85856004');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('ADRENAL', '23451007');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('AMNIOTICFLUID', '77012006');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('ANKLE', '70258002');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('ANTCARDIACV', '194996006');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('ANTCOMMA', '8012006');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('ANTECUBITALV', '128553008');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('ANTSPINALA', '17388009');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('ANTTIBIALA', '68053000');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('ANUSRECTUMSIGMD', '110612005');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('AORTA', '15825003');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('AORTICARCH', '57034009');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('APPENDIX', '66754008');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('ARTERY', '51114001');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('ASCAORTA', '54247002');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('ASCENDINGCOLON', '9040008');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('AXILLA', '91470000');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('AXILLARYA', '67937003');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('AXILLARYV', '68705008');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('AZYGOSVEIN', '72107004');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('BACK', '77568009');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('BASILARA', '59011009');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('BILEDUCT', '28273000');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('BILIARYTRACT', '34707002');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('BLADDERURETHRA', '110837003');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('BRACHIALA', '17137000');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('BRACHIALV', '20115005');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('BRONCHUS', '955009');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('BULB', '21479005');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('BUTTOCK', '46862004');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('CALCANEUS', '80144004');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('CALF', '53840002');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('CARDIOVASCSYS', '113257007');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('CAROTID', '69105007');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('CCA', '32062004');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('CELIACA', '57850000');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('CEPHALICV', '20699002');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('CEREBELLUM', '113305005');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('CEREBHEMISPHERE', '372073000');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('CEREBRALA', '88556005');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('CERVIX', '71252005');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('CFA', '181347005');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('CFV', '397363009');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('CHEEK', '60819002');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('CHOROIDPLEXUS', '80621003');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('CIRCLEOFWILLIS', '11279006');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('CLAVICLE', '51299004');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('COCCYX', '64688005');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('COMILIACA', '73634005');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('COMILIACV', '46027005');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('COMMONBILEDUCT', '79741001');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('CORNEA', '28726007');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('CORONARYARTERY', '41801008');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('CORONARYSINUS', '90219004');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('CSPINE', '122494005');
INSERT INTO LookupBodyPartForImaging (originalValue, parsedValue) VALUES ('CTSPINE', '1217257000');



CREATE TABLE IF NOT EXISTS LookupManufacturerAlias (
    Id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    originalValue VARCHAR(200),
    parsedValue VARCHAR(200)
);

INSERT INTO LookupManufacturerAlias (originalValue, parsedValue) VALUES ('Siemens Healthineers', 'SIEMENS');
INSERT INTO LookupManufacturerAlias (originalValue, parsedValue) VALUES ('Philips Medical Systems', 'PHILIPS');
INSERT INTO LookupManufacturerAlias (originalValue, parsedValue) VALUES ('Philips Healthcare', 'PHILIPS');
INSERT INTO LookupManufacturerAlias (originalValue, parsedValue) VALUES ('Toshiba Medical', 'TOSHIBA');

----------------------------------------------------
