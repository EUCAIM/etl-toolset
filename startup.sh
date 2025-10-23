#!/bin/bash
chmod 777 Database/*
mkdir -m 777 ./postgres_data
mkdir -m 777 -p ./nifi_data/nifi_content_repository ./nifi_data/nifi_data ./nifi_data/nifi_database_repository ./nifi_data/nifi_flowfile_repository ./nifi_data/nifi_provenance_repository ./input_data/clinical_data ./input_data/image_metadata ./staging_data/curated_as_csv/clinical_data ./staging_data/input_as_csv/clinical_data ./staging_data/input_as_csv/image_metadata ./output_data/clinical_data ./output_data/mapping_logs ./output_data/image_metadata ./registry/database ./registry/flow-storage ./TDC_Output
LOCAL_IP=$(hostname -I | awk '{print $1}')
export LOCAL_IP
NIFI_USER="eucaim"
NIFI_PASSWORD="eucaim123456789"
export NIFI_USER
export NIFI_PASSWORD
docker compose down -t 1

docker compose up -d

#echo "ETL webinterface available at http://localhost:8080"
echo "ETL is running, copy input files into the input_data subfolder"