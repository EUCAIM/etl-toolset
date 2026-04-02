#!/bin/bash

set -e  # fail if any command fails
echo "==== RUNNING TEST: processing imaging metadata sample ===="

TEST_CSV="test_data/aaaadcw3slp2bbsux2urluqaae_PreProGlio_DICOM_metadata_testing_02.csv"
INPUT_DIR="input_data/clinical_data"
OUTPUT_DIR="output_data"

cp "$TEST_CSV" "$INPUT_DIR/"
echo "Copied imaging metadata sample file to $INPUT_DIR"

MAX_RETRIES=60   
SLEEP_SEC=5      
COUNT=0
echo "Waiting for output files in $OUTPUT_DIR ..."
until [ "$(ls -A $OUTPUT_DIR 2>/dev/null)" ]; do
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

echo "Test PASSED"
exit 0