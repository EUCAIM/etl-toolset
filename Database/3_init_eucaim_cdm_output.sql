-- Step 3 Eucaim CDM Schema definition: output
CREATE SCHEMA IF NOT EXISTS eucaim_cdm_output;


-- Dataset and Patient
CREATE TABLE IF NOT EXISTS eucaim_cdm_output.dataset (
    dataset_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    Identifier VARCHAR(150),
    dataset_title VARCHAR(150),
    dataset_description VARCHAR(500)
);

CREATE TABLE IF NOT EXISTS eucaim_cdm_output.patient (
    patient_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    Identifier VARCHAR(150) NOT NULL,
    dataset_id INTEGER REFERENCES eucaim_cdm_output.dataset(dataset_id) ON DELETE CASCADE,
    patient_birth_date DATE,
    patient_birth_sex VARCHAR(50),
    patient_gender VARCHAR(50),
    patient_race VARCHAR(50),
    patient_ethnicity VARCHAR(50),
	patient_managing_organization VARCHAR(150),
    patient_diagnostic_category VARCHAR(50),
    patient_deceased boolean DEFAULT false,
    patient_date_of_last_contact DATE,
    patient_cause_of_death VARCHAR(100)
);


-- Entities related with CancerPatient directly: Health Status Assessment, Tumor Marker Test, Family Member History, Lab Test Result, Medical History
CREATE TABLE IF NOT EXISTS eucaim_cdm_output.health_status_assessment (
    assessment_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_id INTEGER REFERENCES eucaim_cdm_output.patient(patient_id) ON DELETE CASCADE,
    assessment_code VARCHAR(50),
    assesment_value_as_number DECIMAL(5,2),
    assesment_value_as_concept VARCHAR(50),
    assesment_value_unit VARCHAR(50),
    assesment_interpretation VARCHAR(250)
);

CREATE TABLE IF NOT EXISTS eucaim_cdm_output.tumor_marker_test (
    tumor_marker_test_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_id INTEGER REFERENCES eucaim_cdm_output.patient(patient_id) ON DELETE CASCADE,
    --cancer_condition_id INTEGER REFERENCES eucaim_cdm_output.cancer_condition(cancer_condition_id) ON DELETE CASCADE,
    tumor_marker_test_category VARCHAR(50),
    tumor_marker_test_code VARCHAR(50),
    tumor_marker_test_as_number DECIMAL(5,2),
    tumor_marker_test_as_concept VARCHAR(50),
    tumor_marker_test_as_unit VARCHAR(50),
    tumor_marker_date DATE,
    tumor_marker_offset_from_diagnosis INTEGER,
    tumor_marker_offset_unit VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS eucaim_cdm_output.family_member_history (
    family_member_history_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_id INTEGER REFERENCES eucaim_cdm_output.patient(patient_id) ON DELETE CASCADE,
    family_member_relationship VARCHAR(100),
    family_member_condition_code VARCHAR(50),
    family_member_condition_present boolean,
    family_member_onset_age INTEGER,
    family_member_onset_age_unit VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS eucaim_cdm_output.lab_test_result (
    lab_test_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_id INTEGER REFERENCES eucaim_cdm_output.patient(patient_id) ON DELETE CASCADE,
    lab_test_code VARCHAR(100),
    lab_test_value_as_concept VARCHAR(150),
    lab_test_value_as_number DECIMAL(5,2),
    lab_test_value_unit VARCHAR(50),
    lab_test_date DATE,
    lab_test_offset_from_diagnosis INTEGER,
    lab_test_offset_unit VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS eucaim_cdm_output.medical_history (
    medical_history_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_id INTEGER REFERENCES eucaim_cdm_output.patient(patient_id) ON DELETE CASCADE,
    medical_history_code VARCHAR(50),
    medical_history_category VARCHAR(50),
    medical_history_onset_age DECIMAL(4,1),
    medical_history_onset_age_unit VARCHAR(50),
    medical_history_value_as_concept VARCHAR(100),
    medical_history_value_as_number DECIMAL(5,2),
    medical_history_value_unit VARCHAR(50)
);



-- Treatments: Surgical Procedure, Medication Administration, Radiotherapy
CREATE TABLE IF NOT EXISTS eucaim_cdm_output.treatment (
    treatment_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_id INTEGER REFERENCES eucaim_cdm_output.patient(patient_id) ON DELETE CASCADE,
    treatment_type VARCHAR(50),
    treatment_response VARCHAR(200),
    treatment_intent VARCHAR(200),
    TreatmentIdentifier VARCHAR(100),
    Episode INTEGER
);

CREATE TABLE IF NOT EXISTS eucaim_cdm_output.radiotherapy (
    treatment_id INTEGER PRIMARY KEY REFERENCES eucaim_cdm_output.treatment(treatment_id) ON DELETE CASCADE,
    radiotherapy_modality VARCHAR(150),
    radiotherapy_technique VARCHAR(150),
    radiotherapy_start_date DATE,
    radiotherapy_end_date DATE,
    radiotherapy_offset_from_diagnosis INTEGER,
    radiotherapy_offset_unit VARCHAR(50),
    radiotherapy_number_of_sessions INTEGER,
    radiotherapy_total_dose DECIMAL(5,2),
    radiotherapy_dose_to_volume DECIMAL(5,2),
    radiotherapy_fractions_delivered INTEGER,
    radiotherapy_dose_unit VARCHAR(50),
    Episode INTEGER
);

CREATE TABLE IF NOT EXISTS eucaim_cdm_output.surgical_procedure (
    treatment_id INTEGER PRIMARY KEY REFERENCES eucaim_cdm_output.treatment(treatment_id) ON DELETE CASCADE,
    surgical_procedure_code VARCHAR(100),
    surgical_procedure_body_site_code VARCHAR(100),
    surgical_procedure_body_site_location VARCHAR(100),
    surgical_procedure_body_site_laterality VARCHAR(100),
    surgical_procedure_offset_from_diagnosis INTEGER,
    surgical_procedure_offset_from_diagnosis_unit VARCHAR(50),
    surgical_procedure_date DATE,	
    Episode INTEGER
);

CREATE TABLE IF NOT EXISTS eucaim_cdm_output.medication_administration (
    treatment_id INTEGER PRIMARY KEY REFERENCES eucaim_cdm_output.treatment(treatment_id) ON DELETE CASCADE,
    medication_code VARCHAR(50),
    medication_start_date DATE,
    medication_end_date DATE,
    medication_offset_from_diagnosis INTEGER,
    medication_offset_unit VARCHAR(50),
    medication_number_of_sessions INTEGER,
    medication_total_dose DECIMAL(5,2),
    medication_dose_unit VARCHAR(50),
    medication_effective_period DECIMAL(4,1),
    medication_effective_period_unit VARCHAR(50),
    Episode INTEGER
);

CREATE TABLE IF NOT EXISTS eucaim_cdm_output.adverse_event (
    adverse_event_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY, 
    treatment_id INTEGER REFERENCES eucaim_cdm_output.treatment(treatment_id) ON DELETE CASCADE,
    adverse_event_resulting_effect VARCHAR(200),
    adverse_event_date DATE
);


-- Cancer Condition, Histologic Grade, Cancer Stage, Procedure, Tumor
CREATE TABLE IF NOT EXISTS eucaim_cdm_output.cancer_condition (
    cancer_condition_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_id INTEGER REFERENCES eucaim_cdm_output.patient(patient_id) ON DELETE CASCADE,
    Identifier VARCHAR(150),
    cancer_condition_age_at_diagnosis DECIMAL(5,2),    
    cancer_condition_age_unit VARCHAR(50),
    cancer_condition_asserted_date DATE,
    cancer_condition_offset_from_primary INTEGER,
    cancer_condition_offset_unit VARCHAR(50),
    cancer_condition_code VARCHAR(50),
    cancer_condition_type VARCHAR(50),
    cancer_condition_histology_morphology VARCHAR(150),
    cancer_condition_topography VARCHAR(150),
    Episode INTEGER
);

CREATE TABLE IF NOT EXISTS eucaim_cdm_output.histologic_grade (
    histologic_grade_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	cancer_condition_id INTEGER REFERENCES eucaim_cdm_output.cancer_condition(cancer_condition_id) ON DELETE CASCADE,
    patient_id INTEGER REFERENCES eucaim_cdm_output.patient(patient_id) ON DELETE CASCADE,
    --procedure_id INTEGER REFERENCES eucaim_cdm_output.procedure(procedure_id),
    histologic_grade_scoring_system VARCHAR(150),
    histologic_grade_code VARCHAR(50),
    histologic_grade_value_as_concept VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS eucaim_cdm_output.cancer_stage (
    cancer_stage_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cancer_condition_id INTEGER REFERENCES eucaim_cdm_output.cancer_condition(cancer_condition_id) ON DELETE CASCADE,
	cancer_stage_code VARCHAR(50),
	cancer_stage_scoring_system VARCHAR(50),
	cancer_stage_as_concept VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS eucaim_cdm_output.procedure (
    procedure_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cancer_condition_id INTEGER REFERENCES eucaim_cdm_output.cancer_condition(cancer_condition_id) ON DELETE CASCADE,
    ProcedureIdentifier VARCHAR(150),
    procedure_code VARCHAR(50),
    procedure_category VARCHAR(50),
    procedure_evaluation_finding VARCHAR(150),
    procedure_offset_from_diagnosis DECIMAL(5,2),
    procedure_offset_unit VARCHAR(50),
    procedure_date DATE,
    ImagingTimepoint INTEGER,
    Episode INTEGER
);

CREATE TABLE IF NOT EXISTS eucaim_cdm_output.tumor (
    tumor_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cancer_condition_id INTEGER REFERENCES eucaim_cdm_output.cancer_condition(cancer_condition_id) ON DELETE CASCADE,
    patient_id INTEGER REFERENCES eucaim_cdm_output.patient(patient_id) ON DELETE CASCADE,
    Identifier VARCHAR(150),
	tumor_is_index BOOLEAN,
	tumor_histology_morphology VARCHAR(50),
	tumor_volume DECIMAL(5,2),
    tumor_volume_unit VARCHAR(50),
	tumor_size_method VARCHAR(50),
	tumor_size_maximum_dimension DECIMAL(5,2),
	tumor_size_other_dimension DECIMAL(5,2),
	tumor_size_dimension_unit VARCHAR (15),
    tumor_body_site VARCHAR(50),
    tumor_body_site_location VARCHAR(150),
    tumor_body_site_laterality VARCHAR(50)
);


-- Entities related with Tumor directly: Risk Assessment, Tumor Observation
CREATE TABLE IF NOT EXISTS eucaim_cdm_output.risk_assessment (
    risk_assessment_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tumor_id INTEGER REFERENCES eucaim_cdm_output.tumor(tumor_id) ON DELETE CASCADE,
    patient_id INTEGER REFERENCES eucaim_cdm_output.patient(patient_id) ON DELETE CASCADE,
	risk_assessment_code VARCHAR(150),
	risk_assessment_value_unit VARCHAR (15),
    risk_assessment_value_as_concept VARCHAR(50),
    risk_assessment_value_as_number INTEGER
);

CREATE TABLE IF NOT EXISTS eucaim_cdm_output.tumor_observation (
    tumor_observation_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	tumor_id INTEGER REFERENCES eucaim_cdm_output.tumor(tumor_id) ON DELETE CASCADE,
    patient_id INTEGER REFERENCES eucaim_cdm_output.patient(patient_id) ON DELETE CASCADE,
	tumor_observation_code VARCHAR(150),
	tumor_observation_value_unit VARCHAR(15),
    tumor_observation_value_as_concept VARCHAR(50),
    tumor_observation_Value_as_number INTEGER
);


-- Episode and Episode Event
CREATE TABLE IF NOT EXISTS eucaim_cdm_output.episode (
    episode_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_id INTEGER REFERENCES eucaim_cdm_output.patient(patient_id) ON DELETE CASCADE,
	episode_type_code VARCHAR(50),
	episode_number INTEGER,
    episode_start_date DATE,
    episode_end_date DATE,
    episode_offset_from_diagnosis DECIMAL(5,2),
    episode_offset_unit VARCHAR(50),
    episode_parent_id INTEGER REFERENCES eucaim_cdm_output.episode(episode_id)
);

CREATE TABLE IF NOT EXISTS eucaim_cdm_output.episode_event (
    episode_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY REFERENCES eucaim_cdm_output.episode(episode_id) ON DELETE CASCADE,
	event_table_id INTEGER,
    event_table_name VARCHAR(150)
);


-- Entities for DICOM metadata
CREATE TABLE IF NOT EXISTS eucaim_cdm_output.image_study (
    study_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    procedure_id INTEGER REFERENCES eucaim_cdm_output.procedure(procedure_id) ON DELETE CASCADE,
    patient_id INTEGER REFERENCES eucaim_cdm_output.patient(patient_id) ON DELETE CASCADE,
    study_uid VARCHAR(70),
    ImagingTimepoint INTEGER,
    study_offset_from_diagnosis DECIMAL(5,2),
    study_offset_unit VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS eucaim_cdm_output.image_series (
    series_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    study_id INTEGER REFERENCES eucaim_cdm_output.image_study(study_id) ON DELETE CASCADE,
    series_uid VARCHAR(70),
    series_number INTEGER,
    series_description VARCHAR(170),
	series_manufacturer VARCHAR(70),
    series_body_side_code VARCHAR(70),
    series_body_side_location VARCHAR(70),
    series_body_side_laterality VARCHAR(70),
    series_acquisition_date DATE,
    series_modality VARCHAR(70)
);

CREATE TABLE IF NOT EXISTS eucaim_cdm_output.image_modality (
    modality_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    series_id INTEGER REFERENCES eucaim_cdm_output.image_series(series_id) ON DELETE CASCADE,
    acquisition_parameter_code VARCHAR(50),
    acquisition_parameter_value_as_code VARCHAR(50),
    acquisition_parameter_value_as_number DECIMAL(5,2),
    acquisition_parameter_value_unit VARCHAR(50)
);