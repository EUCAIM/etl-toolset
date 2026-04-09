#!/bin/bash

### skiping tests (for main branch at least)
### comment this line to enable script
### exit 0


set -e  # fail if any command fails
echo "==== RUNNING TEST: processing imaging metadata sample ===="

INPUT_DIR="input_data"
OUTPUT_DIR="output_data"
POSTGRES_CONTAINER=$(docker compose ps -q nifi-postgres)


### validations for imaging metadata
rm -f $OUTPUT_DIR/*.csv

TEST_CSV="sample_data/4fcdd34b95f8eed2a3d07291e4c2173e_AUTH_dcm_series_metadata_breast_few_studies.csv"
NUMBER_OF_STUDIES=4
cp "$TEST_CSV" "$INPUT_DIR/image_metadata/"
echo "Copied imaging metadata sample file to $INPUT_DIR"

MAX_RETRIES=60   
SLEEP_SEC=5      
COUNT=0
until find "$OUTPUT_DIR" -maxdepth 1 -type f -name "*.csv" | grep -q .; do
  if [ $COUNT -ge $MAX_RETRIES ]; then
    echo "Timeout: No output files detected after $((MAX_RETRIES*SLEEP_SEC)) seconds."
    exit 1
  fi

  echo "Still waiting..."
  sleep $SLEEP_SEC
  COUNT=$((COUNT+1))
done

echo "Output detected!"

echo "Files generated:"
ls -l "$OUTPUT_DIR"

echo "Validating rows number for imaging metadata in output files..."
TOTAL_ROWS=0
for f in $OUTPUT_DIR/image_study*.csv; do
  ROWS=$(($(wc -l < "$f") - 1))
  TOTAL_ROWS=$((TOTAL_ROWS + ROWS))
done

echo "Number of output rows in image_study csv files: $TOTAL_ROWS  (Expected rows: $NUMBER_OF_STUDIES)"

if [ "$TOTAL_ROWS" -eq 0 ]; then
  echo "❌ Not processed data"
  #exit 1
fi

if [ "$TOTAL_ROWS" -ne $NUMBER_OF_STUDIES ]; then
  echo "❌ Output seems not correct"
  #exit 1
fi


echo "Validating rows number for imaging metadata in staging database..."
TOTAL_ROWS=0
TOTAL_ROWS=$(docker exec $POSTGRES_CONTAINER psql -U postgres -d eucaim-etl-db -t -c "SELECT COUNT(*) FROM eucaim_cdm_ingestion.ImageStudy;" | xargs)

echo "Number of output rows in eucaim_cdm_ingestion.ImageStudy table: $TOTAL_ROWS  (Expected rows: $NUMBER_OF_STUDIES)"

if [ "$TOTAL_ROWS" -eq 0 ]; then
  echo "❌ Not processed data"
  exit 1
fi

if [ "$TOTAL_ROWS" -ne $NUMBER_OF_STUDIES ]; then
  echo "❌ Output seems not correct"
  exit 1
fi


### validations for clinical data
rm -f $OUTPUT_DIR/*.csv

TEST_CSV="sample_data/4fcdd34b95f8eed2a3d07291e4c2173e_Breast_Cancer3_sample.csv"
NUMBER_OF_PATIENTS=4
cp "$TEST_CSV" "$INPUT_DIR/clinical_data/"
echo "Copied clinical data sample file to $INPUT_DIR"

MAX_RETRIES=70   
SLEEP_SEC=5      
COUNT=0
until find "$OUTPUT_DIR" -maxdepth 1 -type f -name "*.csv" | grep -q .; do
  if [ $COUNT -ge $MAX_RETRIES ]; then
    echo "Timeout: No output files detected after $((MAX_RETRIES*SLEEP_SEC)) seconds."
    exit 1
  fi

  echo "Still waiting..."
  ls -l "$OUTPUT_DIR"
  sleep $SLEEP_SEC
  COUNT=$((COUNT+1))
done

echo "Output detected!"

echo "Files generated:"
ls -l "$OUTPUT_DIR"

echo "Validating rows number for clinical data in output files..."
TOTAL_ROWS=0
for f in $OUTPUT_DIR/patient*.csv; do
  ROWS=$(($(wc -l < "$f") - 1))
  TOTAL_ROWS=$((TOTAL_ROWS + ROWS))
done

echo "Number of output rows in patient csv files: $TOTAL_ROWS  (Expected rows: $NUMBER_OF_PATIENTS)"

if [ "$TOTAL_ROWS" -eq 0 ]; then
  echo "❌ Not processed data"
  #exit 1
fi

if [ "$TOTAL_ROWS" -ne $NUMBER_OF_PATIENTS ]; then
  echo "❌ Output seems not correct"
  #exit 1
fi

echo "Validating rows numbers for clinical data in staging database..."
TOTAL_ROWS=0
TOTAL_ROWS=$(docker exec $POSTGRES_CONTAINER psql -U postgres -d eucaim-etl-db -t -c "SELECT COUNT(*) FROM eucaim_cdm_ingestion.CancerPatient;" | xargs)

echo "Number of output rows in eucaim_cdm_ingestion.ImageStudy table: $TOTAL_ROWS  (Expected rows: $NUMBER_OF_PATIENTS)"

if [ "$TOTAL_ROWS" -eq 0 ]; then
  echo "❌ Not processed data"
  exit 1
fi

if [ "$TOTAL_ROWS" -ne $NUMBER_OF_PATIENTS ]; then
  echo "❌ Output seems not correct"
  exit 1
fi


### validations for imaging timepoints (TODO)
rm -f $OUTPUT_DIR/*.csv


echo "Test PASSED"
exit 0