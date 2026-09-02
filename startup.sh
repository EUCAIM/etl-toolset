#!/bin/bash

chmod 777 Database/*
mkdir -m 777 -p ./nifi_data/nifi_content_repository ./nifi_data/nifi_data ./nifi_data/nifi_database_repository ./nifi_data/nifi_flowfile_repository ./nifi_data/nifi_provenance_repository  
mkdir -m 777 -p ./input_data/clinical_data ./input_data/image_metadata ./input_data/image_timepoints
mkdir -m 777 -p ./staging_data/curated_as_csv/clinical_data ./staging_data/input_as_csv/clinical_data ./staging_data/input_as_csv/image_metadata ./staging_data/input_as_csv/image_timepoints
mkdir -m 777 -p ./TDC_Output
mkdir -m 777 -p ./output_data ./output_data/mapping_logs ./output_data/etl_process_logs
mkdir -m 777 -p ./registry/database ./registry/flow-storage
mkdir -p ./flows
chmod 777 ./flows

LOCAL_IP=$(hostname -I | awk '{print $1}')
export LOCAL_IP
NIFI_USER="eucaim"
NIFI_PASSWORD="eucaim123456789"
export NIFI_USER
export NIFI_PASSWORD

### node-local configuration, empty in a clean checkout. A value already in the
### environment, as the CI workflow sets, wins over the file, so a datasetsList
### committed here by mistake cannot silently override the datasets under test.
DATASETS_FROM_ENV="$datasetsList"
DOWNLOAD_FROM_ENV="$downloadFlows"
if [ -f ./local_env.sh ]; then
    . ./local_env.sh
fi
if [ -n "$DATASETS_FROM_ENV" ]; then
    datasetsList="$DATASETS_FROM_ENV"
fi
if [ -n "$DOWNLOAD_FROM_ENV" ]; then
    downloadFlows="$DOWNLOAD_FROM_ENV"
fi

### datasets whose mappings init.sh pulls from EUCAIM/etl-mappings. Empty on a
### clean deployment: this node downloads no mapping until its operator selects
### the datasets it serves. The CI workflow sets it to every dataset covered by
### the tests.
export datasetsList
if [ -z "$datasetsList" ]; then
    echo "No dataset selected: export datasetsList with a comma separated list of dataset codes to download their mappings"
else
    echo "Datasets to be deployed: $datasetsList"
fi

### the download overwrites ./flows on every start, so a mapping being adjusted
### locally is lost unless this is turned off. Defaults to the usual behaviour.
downloadFlows="${downloadFlows:-true}"
export downloadFlows
case "$(printf '%s' "$downloadFlows" | tr '[:upper:]' '[:lower:]')" in
    false|no|0|off)
        echo "Mapping download disabled: the flows already in ./flows will be used as they are"
        ;;
esac

### loop04 writes one CSV per export run, so these folders reach hundreds of
### files in a few weeks and stop being readable. The rows they contain stay in
### the ingestion database, which is what the export reads from, so dropping the
### old files loses nothing. Only the files loop04 generates are matched:
### etl-errors.log and its rotations are logback's business, and anything the
### operator put there by hand is left alone. Set to 0 to keep everything.
logsRetentionDays="${logsRetentionDays:-30}"
case "$logsRetentionDays" in
    ''|*[!0-9]*) echo "logsRetentionDays is not a number, skipping the cleanup" ;;
    0) ;;
    *)
        removed=$(find ./output_data/mapping_logs -maxdepth 1 -type f -name 'mapping_results_*_records.csv' -mtime +"$logsRetentionDays" -print -delete 2>/dev/null | wc -l)
        removed=$((removed + $(find ./output_data/etl_process_logs -maxdepth 1 -type f -name 'process_logs_*_records.csv' -mtime +"$logsRetentionDays" -print -delete 2>/dev/null | wc -l)))
        [ "$removed" -gt 0 ] && echo "Removed $removed exported log files older than $logsRetentionDays days"
        ;;
esac

docker compose down -t 1
docker compose up -d

echo "ETL admin web interface available at http://localhost:8080"
echo "ETL is running, copy input files into the input_data subfolder"