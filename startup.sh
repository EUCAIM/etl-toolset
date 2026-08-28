#!/bin/bash

chmod 777 Database/*
mkdir -m 777 -p ./nifi_data/nifi_content_repository ./nifi_data/nifi_data ./nifi_data/nifi_database_repository ./nifi_data/nifi_flowfile_repository ./nifi_data/nifi_provenance_repository  
mkdir -m 777 -p ./input_data/clinical_data ./input_data/image_metadata ./input_data/image_timepoints
mkdir -m 777 -p ./staging_data/curated_as_csv/clinical_data ./staging_data/input_as_csv/clinical_data ./staging_data/input_as_csv/image_metadata ./staging_data/input_as_csv/image_timepoints
mkdir -m 777 -p ./TDC_Output
mkdir -m 777 -p ./output_data ./output_data/mapping_logs
mkdir -m 777 -p ./registry/database ./registry/flow-storage

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
if [ -f ./local_env.sh ]; then
    . ./local_env.sh
fi
if [ -n "$DATASETS_FROM_ENV" ]; then
    datasetsList="$DATASETS_FROM_ENV"
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

docker compose down -t 1
docker compose up -d

echo "ETL admin web interface available at http://localhost:8080"
echo "ETL is running, copy input files into the input_data subfolder"