#!/bin/bash

set -e  # fail if any command fails
set -o pipefail  # a failing command in a pipeline must not be masked by the last one
echo "==== RUNNING TEST: start main ===="

### definitions: global parameters
### anchor every path to the repository root, so the script behaves the same
### no matter which directory it is invoked from
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INPUT_DIR="$ROOT_DIR/input_data"
OUTPUT_DIR="$ROOT_DIR/output_data"
SAMPLE_DIR="$ROOT_DIR/sample_data"
SCRIPTS_DIR="$ROOT_DIR/scripts"
POSTGRES_CONTAINER=$(docker compose -f "$ROOT_DIR/docker-compose.yaml" ps -q nifi-postgres)

MAX_RETRIES=60
SLEEP_SEC=5
COUNT=0


diagnosticar_atasco() {
  echo ""
  echo "======== DIAGNOSIS: pipeline stalled on ${NAME:-?} (${CODE:-?}) ========"

  echo "-------- services: a container that is not Up explains everything"
  docker compose -f "$ROOT_DIR/docker-compose.yaml" ps 2>/dev/null || true

  echo "-------- flows loaded into NiFi: the loop03 of this dataset must be here"
  docker exec nifi sh -c 'ls -1 /flows' 2>/dev/null || echo "  (cannot read /flows)"

  echo "-------- stage by stage (empty marks where it stopped)"
  for d in "$INPUT_DIR/clinical_data" \
           "$ROOT_DIR/staging_data/input_as_csv/clinical_data" \
           "$ROOT_DIR/TDC_Output" \
           "$ROOT_DIR/staging_data/curated_as_csv/clinical_data" \
           "$OUTPUT_DIR"; do
    n=$(find "$d" -maxdepth 1 -type f 2>/dev/null | wc -l)
    printf '  %-52s %s files\n' "${d#$ROOT_DIR/}" "$n"
  done

  echo "-------- rows already ingested for this dataset"
  docker exec "$POSTGRES_CONTAINER" psql -U postgres -d eucaim-etl-db -t -c "
    SELECT 'cancerpatient=' || count(*) FROM eucaim_cdm_ingestion.cancerpatient
    WHERE datasetidentifier='${CODE}';" 2>/dev/null | xargs || true

  ### init.sh runs when the container boots, so its output sits at the top of
  ### the log and a plain tail never reaches it
  echo "-------- mapping download (init.sh, start of the nifi log)"
  docker logs nifi 2>&1 | grep -E "Repository:|Branch:|Downloading:|DATASETSLIST|Download flows ended|Flow insertion outcome" || echo "  (no trace of the download)"

  echo "-------- last 60 log lines of each container"
  docker logs --tail 60 nifi-tdc 2>&1 || true
  docker logs --tail 60 nifi 2>&1 || true
  echo "======== END OF DIAGNOSIS ========"
  echo ""
}

### definitions: validations for clinical data
procesar_pipeline_clinical_data() {
  rm -f $OUTPUT_DIR/*.csv
  COUNT=0
  cp "$CLINICAL_DATA_TEST_CSV" "$INPUT_DIR/clinical_data/"
  echo "Copied clinical data sample file to $INPUT_DIR"

  until [ -n "$(find "$OUTPUT_DIR" -maxdepth 1 -type f -name "*.csv" -print -quit)" ]; do
    if [ $COUNT -ge $MAX_RETRIES ]; then
      echo "Timeout: No output files detected after $((MAX_RETRIES*SLEEP_SEC)) seconds."
      diagnosticar_atasco
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

  ### the output files are per-batch logs of the records written, not a final
  ### snapshot: a patient is exported again every time the mapping rewrites its
  ### row, which happens once per source row. Datasets carrying several rows per
  ### patient therefore span several files with repeated identifiers, so what
  ### has to match the dataset is the number of distinct identifiers (first
  ### column) rather than the sum of the rows.
  echo "Validating rows number for clinical data in output files..."
  TOTAL_ROWS=$(for f in "$OUTPUT_DIR"/patient*.csv; do
      [ -f "$f" ] || continue   ### an unmatched glob must not abort under pipefail
      tail -n +2 "$f"
    done | cut -d',' -f1 | awk 'NF' | sort -u | wc -l)

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
  COUNT=0
  cp "$IMAGE_METADATA_TEST_CSV" "$INPUT_DIR/image_metadata/"
  echo "Copied imaging metadata sample file to $INPUT_DIR"

  until [ -n "$(find "$OUTPUT_DIR" -maxdepth 1 -type f -name "*.csv" -print -quit)" ]; do
    if [ $COUNT -ge $MAX_RETRIES ]; then
      echo "Timeout: No output files detected after $((MAX_RETRIES*SLEEP_SEC)) seconds."
      diagnosticar_atasco
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

  ### same per-batch logs as for the patients, but here the first column is the
  ### autoincremental id, so the study is identified by study_uid, the second
  ### column of the LoadNewImageStudy query
  echo "Validating rows number for imaging metadata in output files..."
  TOTAL_ROWS=$(for f in "$OUTPUT_DIR"/image_study*.csv; do
      [ -f "$f" ] || continue   ### an unmatched glob must not abort under pipefail
      tail -n +2 "$f"
    done | cut -d',' -f2 | awk 'NF' | sort -u | wc -l)

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
  COUNT=0
  cp "$IMAGING_TIMEPOINTS_TEST_CSV" "$INPUT_DIR/image_timepoints/"
  echo "Copied imaging timepoints sample file to $INPUT_DIR"

  echo "Validating rows numbers in output database..."

  TOTAL_ROWS=0
  until [ "$TOTAL_ROWS" -ne 0 ]; do
    if [ $COUNT -ge $MAX_RETRIES ]; then
      echo "Timeout: No output files detected after $((MAX_RETRIES*SLEEP_SEC)) seconds."
      diagnosticar_atasco
      exit 1
    fi
    ### this query polls a pipeline that is still running, so a transient
    ### failure means "not ready yet" rather than a test failure
    TOTAL_ROWS=$(docker exec $POSTGRES_CONTAINER psql -U postgres -d eucaim-etl-db -t -c "SELECT COUNT(*) FROM eucaim_cdm_output.patient where dataset_id = '${CODE}';" | xargs) || TOTAL_ROWS=0
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
### the config file is redirected instead of piped, so the loop runs in this
### shell (PIPELINES_RUN survives, and a failing test aborts the script) and a
### missing config file fails the redirection instead of silently looping zero
### times
PIPELINES_RUN=0

{
read -r _CONFIG_HEADER
while IFS=',' read -r NAME CODE NUMBER_OF_PATIENTS NUMBER_OF_STUDIES DCM
do
	NAME=${NAME%$'\r'}
	CODE=${CODE%$'\r'}
	NUMBER_OF_PATIENTS=${NUMBER_OF_PATIENTS%$'\r'}
	NUMBER_OF_STUDIES=${NUMBER_OF_STUDIES%$'\r'}
	DCM=${DCM%$'\r'}
	declare -p NAME CODE NUMBER_OF_PATIENTS NUMBER_OF_STUDIES DCM
	CLINICAL_DATA_TEST_CSV="$SAMPLE_DIR/${CODE}_clinical_data_testing.csv"
	IMAGE_METADATA_TEST_CSV="$SAMPLE_DIR/${CODE}_DICOM_metadata_testing.csv"
	IMAGING_TIMEPOINTS_TEST_CSV="$SAMPLE_DIR/${CODE}_imaging_timepoints_testing.csv"

	CLINICAL_DATA_EXTRA_TEST_SCRIPT="$SCRIPTS_DIR/${CODE}_run_clinical_data_specific_tests.sh"
	TIMEPOINTS_EXTRA_TEST_SCRIPT="$SCRIPTS_DIR/${CODE}_run_imaging_timepoints_specific_tests.sh"

	echo "$CLINICAL_DATA_TEST_CSV"

	if [ -f $CLINICAL_DATA_TEST_CSV ]; then
	  procesar_pipeline_clinical_data
	  PIPELINES_RUN=$((PIPELINES_RUN+1))

	  if [ -f $CLINICAL_DATA_EXTRA_TEST_SCRIPT ]; then
		echo "Detected additional clinical data tests on: $CLINICAL_DATA_EXTRA_TEST_SCRIPT"
		source $CLINICAL_DATA_EXTRA_TEST_SCRIPT
	  fi
	fi

	sleep $SLEEP_SEC
	
	if [ "$DCM" -eq 1 ]; then
		if [ -f $IMAGE_METADATA_TEST_CSV ]; then
		  procesar_pipeline_imaging_metadata
		  PIPELINES_RUN=$((PIPELINES_RUN+1))
		fi

		sleep $SLEEP_SEC


		if [ -f $IMAGING_TIMEPOINTS_TEST_CSV ]; then
		  procesar_pipeline_imaging_timepoints
		  PIPELINES_RUN=$((PIPELINES_RUN+1))

		  ### checks that need the output CDM fully populated, so they can only
		  ### run once the timepoints pipeline has linked studies to procedures
		  if [ -f $TIMEPOINTS_EXTRA_TEST_SCRIPT ]; then
			echo "Detected additional imaging timepoints tests on: $TIMEPOINTS_EXTRA_TEST_SCRIPT"
			source $TIMEPOINTS_EXTRA_TEST_SCRIPT
		  fi
		fi
	fi

done
} < "$SCRIPTS_DIR/config.csv"

### closing tests
### reaching this point having validated nothing means the sample files are
### missing or misnamed, which must not be reported as a pass
if [ "$PIPELINES_RUN" -eq 0 ]; then
  echo "❌ No pipeline was executed: check that $SAMPLE_DIR holds the sample files named after the codes in config.csv"
  exit 1
fi

echo "Test PASSED ($PIPELINES_RUN pipelines executed)"
echo "==== RUNNING TEST: close main ===="
exit 0

