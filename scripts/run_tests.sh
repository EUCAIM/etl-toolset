#!/bin/bash

set -e  # fail if any command fails
echo "==== RUNNING TEST: processing imaging metadata sample ===="

INPUT_DIR="input_data"
OUTPUT_DIR="output_data"


### validations for clinical data  (TODO)



### validations for imaging metadata
TEST_CSV="test_data/aaaadcw3slp2bbsux2urluqaae_PreProGlio_DICOM_metadata_testing_02.csv"
NUMBER_OF_STUDIES=3
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

if [ "$TOTAL_ROWS" -ne $NUMBER_OF_STUDIES ]; then
  echo "❌ Output seems not correct"
  exit 1
fi


### validations for imaging timepoints (TODO)



echo "Test PASSED"
exit 0