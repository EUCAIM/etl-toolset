#!/bin/bash

set -e  # fail if any command fails
echo "==== RUNNING TEST: start main ===="

### definitions: global parameters
INPUT_DIR="../input_data"
OUTPUT_DIR="../output_data"
POSTGRES_CONTAINER=$(docker compose ps -q nifi-postgres)

MAX_RETRIES=60   
SLEEP_SEC=5      
COUNT=0

### definitions: validations for clinical data
procesar_pipeline_clinical_data() {
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
  TOTAL_ROWS=$(docker exec $POSTGRES_CONTAINER psql -U postgres -d eucaim-etl-db -t -c "SELECT COUNT(*) FROM eucaim_cdm_ingestion.CancerPatient where datasetidentifier = '${CODE}';" | xargs)

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
  TOTAL_ROWS=$(docker exec $POSTGRES_CONTAINER psql -U postgres -d eucaim-etl-db -t -c "SELECT COUNT(*) FROM eucaim_cdm_ingestion.ImageStudy where datasetidentifier = '${CODE}';" | xargs)

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
    TOTAL_ROWS=$(docker exec $POSTGRES_CONTAINER psql -U postgres -d eucaim-etl-db -t -c "SELECT COUNT(*) FROM eucaim_cdm_output.patient where dataset_id = '${CODE}';" | xargs)
    echo "Still waiting..."
    sleep $SLEEP_SEC
    COUNT=$((COUNT+1))
  done

  sleep $SLEEP_SEC
  sleep $SLEEP_SEC
  sleep $SLEEP_SEC
  sleep $SLEEP_SEC
  
  echo "Number of output rows in eucaim_cdm_output.patient table: $TOTAL_ROWS  (Expected rows: $NUMBER_OF_PATIENTS)"

  if [ "$TOTAL_ROWS" -ne $NUMBER_OF_PATIENTS ]; then
    echo "❌ Output seems not correct"
    exit 1
  fi
}


### executing tests
tail -n +2 config.csv | while IFS=',' read -r NAME CODE NUMBER_OF_PATIENTS NUMBER_OF_STUDIES DCM
do
	NAME=${NAME%$'\r'}
	CODE=${CODE%$'\r'}
	NUMBER_OF_PATIENTS=${NUMBER_OF_PATIENTS%$'\r'}
	NUMBER_OF_STUDIES=${NUMBER_OF_STUDIES%$'\r'}
	DCM=${DCM%$'\r'}
	declare -p NAME CODE NUMBER_OF_PATIENTS NUMBER_OF_STUDIES DCM
	CLINICAL_DATA_TEST_CSV="../sample_data/${CODE}_clinical_data_testing.csv"
	IMAGE_METADATA_TEST_CSV="../sample_data/${CODE}_DICOM_metadata_testing.csv"
	IMAGING_TIMEPOINTS_TEST_CSV="../sample_data/${CODE}_imaging_timepoints_testing.csv"

	CLINICAL_DATA_EXTRA_TEST_SCRIPT="../scripts/${CODE}_run_clinical_data_specific_tests.sh"

	echo "$CLINICAL_DATA_TEST_CSV"

	if [ -f $CLINICAL_DATA_TEST_CSV ]; then
	  procesar_pipeline_clinical_data

	  if [ -f $CLINICAL_DATA_EXTRA_TEST_SCRIPT ]; then
		echo "Detected additional clinical data tests on: $CLINICAL_DATA_EXTRA_TEST_SCRIPT"
		source $CLINICAL_DATA_EXTRA_TEST_SCRIPT
	  fi
	fi

	sleep $SLEEP_SEC
	
	if ["$DCM" -eq 1]; then
		if [ -f $IMAGE_METADATA_TEST_CSV ]; then
		  procesar_pipeline_imaging_metadata
		fi

		sleep $SLEEP_SEC


		if [ -f $IMAGING_TIMEPOINTS_TEST_CSV ]; then
		  procesar_pipeline_imaging_timepoints
		fi
	fi

done

### closing tests
echo "Test PASSED"
echo "==== RUNNING TEST: close main ===="
exit 0

