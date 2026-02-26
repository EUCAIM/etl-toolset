CREATE OR REPLACE PROCEDURE eucaim_etl_aux.insert_log_v001(p_filename text, p_datasetId text, log_datasettype text, log_pipelinestage text, log_stepnumber text, log_stepname text, log_level text, log_status text, log_message text)
LANGUAGE plpgsql
SET search_path = eucaim_etl_aux, eucaim_cdm_ingestion, cdm_cdm_output
AS $$
BEGIN
    -- Insert log entry
    INSERT INTO eucaim_cdm_ingestion.ProcessLog(filename, datasetId, datasetType, pipelineStage, stepNumber, stepName, level, status, message, timestamp)
    VALUES (p_filename, p_datasetId, log_datasettype, log_pipelinestage, CAST(log_stepnumber AS INTEGER), log_stepname, log_level, log_status, log_message, CURRENT_TIMESTAMP);

END;
$$;
