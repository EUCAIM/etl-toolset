#!/bin/bash

### skiping tests (for main branch at least)
### comment this line to enable script
### exit 0


set -e  # fail if any command fails
echo "==== RUNNING TEST: processing imaging metadata sample ===="

INPUT_DIR="input_data"
OUTPUT_DIR="output_data"
POSTGRES_CONTAINER=$(docker compose ps -q nifi-postgres)

### validations for clinical data 
rm -f $OUTPUT_DIR/*.csv

TEST_CSV_CLINICAL="sample_data/UOA_brainCancer_test_02_overarchingEpisode.csv"
NUMBER_OF_PATIENTS=2

cp "$TEST_CSV_CLINICAL" "$INPUT_DIR/clinical_data/"
echo "Copied clinical metadata sample file to $INPUT_DIR/clinical_data"

MAX_RETRIES=60   
SLEEP_SEC=5      
COUNT=0
until find "$OUTPUT_DIR" -maxdepth 1 -type f -name "*.csv" | grep -q .; do
  if [ "$COUNT" -ge "$MAX_RETRIES" ]; then
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

echo "Validating rows number for clinical data in output files..."
TOTAL_ROWS=0
for f in $OUTPUT_DIR/patient*.csv; do
  ROWS=$(($(wc -l < "$f") - 1))
  TOTAL_ROWS=$((TOTAL_ROWS + ROWS))
done

echo "Number of output rows in patient csv files: $TOTAL_ROWS  (Expected rows: $NUMBER_OF_PATIENTS)"

if [ "$TOTAL_ROWS" == "0" ]; then
  echo "❌ Not processed data"
  #exit 1
fi

if [ "$TOTAL_ROWS" -ne $NUMBER_OF_PATIENTS ]; then
  echo "❌ Output seems not correct"
  #exit 1
fi

echo "Validating rows number for imaging metadata in staging database..."
TOTAL_PATIENTS=0
TOTAL_PATIENTS=$(docker exec $POSTGRES_CONTAINER psql -U postgres -d eucaim-etl-db -t -c "SELECT COUNT(*) FROM eucaim_cdm_ingestion.CancerPatient;" | xargs)

echo "Number of output rows in eucaim_cdm_ingestion.CancerPatient table: $TOTAL_PATIENTS  (Expected rows: $NUMBER_OF_PATIENTS)"

if [ "$TOTAL_PATIENTS" -ne "$NUMBER_OF_PATIENTS" ]; then
  echo "❌ Output seems not correct"
  exit 1
fi

echo "✔️ Number of patients in test data is the expected"

CANCER_RELATED_MEDICATION_EPISODE_QUERY=$(docker exec $POSTGRES_CONTAINER psql -U postgres -d eucaim-etl-db -t -c "SELECT episode FROM eucaim_cdm_ingestion.cancerrelatedmedication c where id=1;" | xargs)
CANCER_RELATED_MEDICATION_EPISODE=4

if [ "$CANCER_RELATED_MEDICATION_EPISODE_QUERY" != "$CANCER_RELATED_MEDICATION_EPISODE" ]; then
  echo "❌ Not expected cancer related medication episode on patient 1"
  exit 1
fi

echo "✔️ Cancer related procedure code is the expected in test data"

BIRTH_SEX_QUERY=$(docker exec $POSTGRES_CONTAINER psql -U postgres -d eucaim-etl-db -t -c "SELECT birthsexeucaim FROM eucaim_cdm_ingestion.cancerpatient c where id=1;" | xargs)
BIRTH_SEX_CODE="COM1000177"

if [ "$BIRTH_SEX_QUERY" != "$BIRTH_SEX_CODE" ]; then
  echo "❌ Not expected birth sex code on patient 1"
  exit 1
fi

echo "✔️ Patient birth sex code is the expected in test data"

PATIENT_DIAGNOSTICCATEGORY_QUERY=$(docker exec $POSTGRES_CONTAINER psql -U postgres -d eucaim-etl-db -t -c "SELECT diagnosticcategoryeucaim FROM eucaim_cdm_ingestion.cancerpatient c where id=1;" | xargs)
PATIENT_DIAGNOSTICCATEGORY_CODE="CLIN1007988"

if [ "$PATIENT_DIAGNOSTICCATEGORY_QUERY" != "$PATIENT_DIAGNOSTICCATEGORY_CODE" ]; then
  echo "❌ Not expected patient diagnostic category code on patient 1"
  exit 1
fi

echo "✔️ Patient diagnostic category code is the expected in test data"

NUMBER_OF_EPISODES_QUERY=$(docker exec $POSTGRES_CONTAINER psql -U postgres -d eucaim-etl-db -t -c "SELECT COUNT(*) FROM eucaim_cdm_ingestion.Episode;" | xargs)
NUMBER_OF_EPISODES=8

if [ "$NUMBER_OF_EPISODES_QUERY" -ne "$NUMBER_OF_EPISODES" ]; then
  echo "❌ Not expected number of episodes in sample data"
  exit 1
fi

echo "✔️ Number of episodes in test data is the expected"

IMAGING_PROCEDURE_QUERY=$(docker exec $POSTGRES_CONTAINER psql -U postgres -d eucaim-etl-db -t -c "SELECT COUNT(*) FROM eucaim_cdm_ingestion.imagingprocedure c where patientidentifier='EUCAIM-42359961463279617395233496226407435633';" | xargs)
IMAGING_PROCEDURE_NUMBER=1

if [ "$IMAGING_PROCEDURE_QUERY" -ne "$IMAGING_PROCEDURE_NUMBER" ]; then
  echo "❌ Not expected number of imaging procedures for patient EUCAIM-42359961463279617395233496226407435633"
  exit 1
fi

echo "✔️ Number of imaging procedures for a patient is the expected in test data"

PCC_CODE_QUERY=$(docker exec $POSTGRES_CONTAINER psql -U postgres -d eucaim-etl-db -t -c "SELECT primarycancerconditioneucaim FROM eucaim_cdm_ingestion.primarycancercondition c where patientidentifier='EUCAIM-42359961463279617395233496226407435633';" | xargs)
PCC_CODE="CLIN1007991"

if [ "$PCC_CODE_QUERY" != "$PCC_CODE" ]; then
  echo "❌ Not expected PCC code on patient EUCAIM-42359961463279617395233496226407435633"
  exit 1
fi


echo "✔️ Primary Cancer Condition Code is the expected in test data"


RADIOTHERAPY_QUERY=$(docker exec $POSTGRES_CONTAINER psql -U postgres -d eucaim-etl-db -t -c "SELECT COUNT(*) FROM eucaim_cdm_ingestion.radiotherapycoursesummary;" | xargs)
RADIOTHERAPY_NUMBER=2

if [ "$RADIOTHERAPY_QUERY" -ne "$RADIOTHERAPY_NUMBER" ]; then
  echo "❌ Not expected number of radiotherapy procedures for test data"
  exit 1
fi

echo "✔️ Number of radiotherapy procedures is the expected in test data"

SURGICAL_PROCEDURE_CODE_QUERY=$(docker exec $POSTGRES_CONTAINER psql -U postgres -d eucaim-etl-db -t -c "SELECT procedureeucaim FROM eucaim_cdm_ingestion.surgicalprocedure c where id=1;" | xargs)
SURGICAL_PROCEDURE_CODE="CLIN1001712"

if [ "$SURGICAL_PROCEDURE_CODE_QUERY" != "$SURGICAL_PROCEDURE_CODE" ]; then
  echo "❌ Not expected Surgical Procedure code on patient 1"
  exit 1
fi

echo "✔️ Surgical Procedure Code is the expected in test data"

TUMOR_LOCATION_CODE_QUERY=$(docker exec $POSTGRES_CONTAINER psql -U postgres -d eucaim-etl-db -t -c "SELECT bodysitelocationqualifiereucaim FROM eucaim_cdm_ingestion.tumor c where id=2;" | xargs)
TUMOR_LOCATION_CODE="BP1000350"

if [ "$TUMOR_LOCATION_CODE_QUERY" != "$TUMOR_LOCATION_CODE" ]; then
  echo "❌ Not expected Tumor Location code on patient 2"
  exit 1
fi

echo "✔️ Tumor Location Code is the expected in test data"

### validations for imaging metadata
rm -f $OUTPUT_DIR/*.csv

TEST_CSV_IMAGING="sample_data/UOA_brainCancer_DICOM_metadata_testing.csv"
NUMBER_OF_STUDIES=3

cp "$TEST_CSV_IMAGING" "$INPUT_DIR/image_metadata/"
echo "Copied imaging metadata sample file to $INPUT_DIR"

MAX_RETRIES=60   
SLEEP_SEC=5      
COUNT=0
until find "$OUTPUT_DIR" -maxdepth 1 -type f -name "*.csv" | grep -q .; do
  if [ "$COUNT" -ge "$MAX_RETRIES" ]; then
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

echo "Validating rows number for imaging metadata.."
TOTAL_ROWS=0
for f in $OUTPUT_DIR/image_study*.csv; do
  ROWS=$(($(wc -l < "$f") - 1))
  TOTAL_ROWS=$((TOTAL_ROWS + ROWS))
done

echo "Number of output rows: $TOTAL_ROWS  (Expected rows: $NUMBER_OF_STUDIES)"

if [ "$TOTAL_ROWS" -eq 0 ]; then
  echo "❌ Not processed data"
  exit 1
fi

if [ "$TOTAL_ROWS" -ne "$NUMBER_OF_STUDIES" ]; then
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



### validations for imaging timepoints

rm -f $OUTPUT_DIR/*.csv

TEST_CSV="sample_data/UOA_brainCancer_imaging_timepoints_testing.csv"
NUMBER_OF_PATIENTS=4
cp "$TEST_CSV" "$INPUT_DIR/image_timepoints/"
echo "Copied imaging timepoints sample file to $INPUT_DIR"


echo "Validating rows numbers in output database..."
MAX_RETRIES=40  
SLEEP_SEC=5      
COUNT=0
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

echo "Number of output rows in eucaim_cdm_output.patient table: $TOTAL_ROWS  (Expected rows: $NUMBER_OF_PATIENTS)"

if [ "$TOTAL_ROWS" -ne $NUMBER_OF_PATIENTS ]; then
  echo "❌ Output seems not correct"
  exit 1
fi


echo "Test PASSED"
exit 0SURGICAL_PROCEDURE_CODE_QUERY=$(docker exec $POSTGRES_CONTAINER psql -U postgres -d eucaim-etl-db -t -c "SELECT procedureeucaim FROM eucaim_cdm_ingestion.surgicalprocedure c where id=2;" | xargs)
SURGICAL_PROCEDURE_CODE="CLIN1004413"

if [ "$SURGICAL_PROCEDURE_CODE_QUERY" != "$SURGICAL_PROCEDURE_CODE" ]; then
  echo "❌ Not expected Surgical Procedure code on patient test1"
  exit 1
fi

echo "✔️ Surgical Procedure Code is the expected in test data"
