#!/bin/bash

set -e  # fail if any command fails
echo "==== RUNNING TEST: start main ===="

### definitions: global parameters
INPUT_DIR="input_data"
OUTPUT_DIR="output_data"
POSTGRES_CONTAINER=$(docker compose ps -q nifi-postgres)

CLINICAL_DATA_TEST_CSV="sample_data/de3702e869557fc5981859b7811e3eab_SAMPLE_KI.csv"
NUMBER_OF_PATIENTS=20
IMAGE_METADATA_TEST_CSV="sample_data/de3702e869557fc5981859b7811e3eab_SAMPLE_KI_DICOM_metadata.csv"
NUMBER_OF_STUDIES=3
IMAGING_TIMEPOINTS_TEST_CSV="sample_data/de3702e869557fc5981859b7811e3eab_SAMPLE_KI_imaging_timepoints.csv"

CLINICAL_DATA_EXTRA_TEST_SCRIPT="scripts/run_clinical_data_specific_tests.sh"

MAX_RETRIES=60
SLEEP_SEC=5
COUNT=0


### definitions: validations for clinical data
procesar_pipeline_clinical_data() {
  COUNT=0
  rm -f $OUTPUT_DIR/*.csv
  cp "$CLINICAL_DATA_TEST_CSV" "$INPUT_DIR/clinical_data/"
  echo "Copied clinical data sample file to $INPUT_DIR"

  until find "$OUTPUT_DIR" -maxdepth 1 -type f -name "*.csv" | grep -q .; do
    if [ $COUNT -ge $MAX_RETRIES ]; then
      echo "Timeout: No output files detected after $((MAX_RETRIES*SLEEP_SEC)) seconds."
      docker logs nifi-tdc
      docker logs nifi
      exit 1
    fi

    echo "Still waiting..."
    sleep $SLEEP_SEC
    COUNT=$((COUNT+1))
  done

  sleep $SLEEP_SEC
  sleep $SLEEP_SEC
  sleep $SLEEP_SEC
  sleep $SLEEP_SEC
  sleep $SLEEP_SEC

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
    exit 1
  fi

  if [ "$TOTAL_ROWS" -ne $NUMBER_OF_PATIENTS ]; then
    echo "❌ Output seems not correct"
    exit 1
  fi

  echo "Validating rows numbers for clinical data in staging database..."
  TOTAL_ROWS=0
  TOTAL_ROWS=$(docker exec $POSTGRES_CONTAINER psql -U postgres -d eucaim-etl-db -t -c "SELECT COUNT(*) FROM eucaim_cdm_ingestion.CancerPatient;" | xargs)

  echo "Number of output rows in eucaim_cdm_ingestion.CancerPatient table: $TOTAL_ROWS  (Expected rows: $NUMBER_OF_PATIENTS)"

  if [ "$TOTAL_ROWS" -eq 0 ]; then
    echo "❌ Not processed data"
    exit 1
  fi

  if [ "$TOTAL_ROWS" -ne $NUMBER_OF_PATIENTS ]; then
    echo "❌ Output seems not correct"
    exit 1
  fi
}


### definitions: validations for imaging metadata pipelines
procesar_pipeline_imaging_metadata() {
  COUNT=0
  rm -f $OUTPUT_DIR/*.csv
  cp "$IMAGE_METADATA_TEST_CSV" "$INPUT_DIR/image_metadata/"
  echo "Copied imaging metadata sample file to $INPUT_DIR"

  until find "$OUTPUT_DIR" -maxdepth 1 -type f -name "*.csv" | grep -q .; do
    if [ $COUNT -ge $MAX_RETRIES ]; then
      echo "Timeout: No output files detected after $((MAX_RETRIES*SLEEP_SEC)) seconds."
      docker logs nifi-tdc
      docker logs nifi
      exit 1
    fi

    echo "Still waiting..."
    sleep $SLEEP_SEC
    COUNT=$((COUNT+1))
  done

  sleep $SLEEP_SEC
  sleep $SLEEP_SEC
  sleep $SLEEP_SEC

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
    exit 1
  fi

  if [ "$TOTAL_ROWS" -ne $NUMBER_OF_STUDIES ]; then
    echo "❌ Output seems not correct"
    exit 1
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
}


### definitions: validations for imaging timepoints pipelines
procesar_pipeline_imaging_timepoints() {
  COUNT=0
  rm -f $OUTPUT_DIR/*.csv
  cp "$IMAGING_TIMEPOINTS_TEST_CSV" "$INPUT_DIR/image_timepoints/"
  echo "Copied imaging timepoints sample file to $INPUT_DIR"

  echo "Validating rows numbers in output database..."

  TOTAL_ROWS=0
  until [ "$TOTAL_ROWS" -ne 0 ]; do
    if [ $COUNT -ge $MAX_RETRIES ]; then
      echo "Timeout: No output files detected after $((MAX_RETRIES*SLEEP_SEC)) seconds."
      docker logs nifi-tdc
      docker logs nifi
      exit 1
    fi
    TOTAL_ROWS=$(docker exec $POSTGRES_CONTAINER psql -U postgres -d eucaim-etl-db -t -c "SELECT COUNT(*) FROM eucaim_cdm_output.patient;" | xargs)
    echo "Still waiting..."
    sleep $SLEEP_SEC
    COUNT=$((COUNT+1))
  done

  sleep $SLEEP_SEC
  sleep $SLEEP_SEC

  echo "Number of output rows in eucaim_cdm_output.patient table: $TOTAL_ROWS  (Expected rows: $NUMBER_OF_PATIENTS)"

  if [ "$TOTAL_ROWS" -ne $NUMBER_OF_PATIENTS ]; then
    echo "❌ Output seems not correct"
    exit 1
  fi

  LINKED_STUDIES=$(docker exec $POSTGRES_CONTAINER psql -U postgres -d eucaim-etl-db -t -c "SELECT COUNT(*) FROM eucaim_cdm_output.image_study;" | xargs)
  echo "ℹ️  Rows in eucaim_cdm_output.image_study: $LINKED_STUDIES (0 while the KI mapping does not produce ImagingProcedure)"
}


### executing tests
if [ -f $CLINICAL_DATA_TEST_CSV ]; then
  procesar_pipeline_clinical_data

  if [ -f $CLINICAL_DATA_EXTRA_TEST_SCRIPT ]; then
    echo "Detected additional clinical data tests on: $CLINICAL_DATA_EXTRA_TEST_SCRIPT"
    source $CLINICAL_DATA_EXTRA_TEST_SCRIPT
  fi
fi

sleep $SLEEP_SEC

if [ -f $IMAGE_METADATA_TEST_CSV ]; then
  procesar_pipeline_imaging_metadata
fi

sleep $SLEEP_SEC

if [ -f $IMAGING_TIMEPOINTS_TEST_CSV ]; then
  procesar_pipeline_imaging_timepoints
fi


### closing tests
echo "Test PASSED"
echo "==== RUNNING TEST: close main ===="
exit 0
