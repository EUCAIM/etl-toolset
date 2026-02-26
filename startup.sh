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

docker compose down -t 1
docker compose up -d

echo "ETL admin web interface available at http://localhost:8080"
echo "ETL is running, copy input files into the input_data subfolder"