#!/bin/bash
echo "==== RUNNING TEST: start clinical data specific tests ===="

### this mapping builds its identifiers as <patient>_..., without the dataset
### code in front, so every query is joined up to CancerPatient to keep it
### scoped to ${CODE}: the whole config.csv runs against a single database.

IMAGING_PROCEDURE_QUERY=$(docker exec $POSTGRES_CONTAINER psql -U postgres -d eucaim-etl-db -t -c "SELECT COUNT(*) FROM eucaim_cdm_ingestion.imagingprocedure i join eucaim_cdm_ingestion.cancerpatient p on p.identifier = i.patientidentifier and p.datasetidentifier='${CODE}' where i.patientidentifier='EUCAIM-122786961168182220732412405780701540062';" | xargs)
IMAGING_PROCEDURE_NUMBER=2

if [ "$IMAGING_PROCEDURE_QUERY" -ne "$IMAGING_PROCEDURE_NUMBER" ]; then
  echo "❌ Not expected number of imaging procedures for patient EUCAIM-122786961168182220732412405780701540062"
  exit 1
fi

echo "✔️ Number of imaging procedures for a patient is the expected in test data"


### _test_1 is the HER2 marker (CLIN1044953) in this mapping
TUMOR_MARKER_TEST_CODE_QUERY=$(docker exec $POSTGRES_CONTAINER psql -U postgres -d eucaim-etl-db -t -c "SELECT t.tumormarkereucaim FROM eucaim_cdm_ingestion.tumormarkertest t join eucaim_cdm_ingestion.cancerpatient p on p.identifier = t.patientidentifier and p.datasetidentifier='${CODE}' where t.identifier='EUCAIM-122786961168182220732412405780701540062_test_1';" | xargs)
TUMOR_MARKER_TEST_CODE="CLIN1044953"

if [ "$TUMOR_MARKER_TEST_CODE_QUERY" != "$TUMOR_MARKER_TEST_CODE" ]; then
  echo "❌ Not expected Tumor Marker Test on patient EUCAIM-122786961168182220732412405780701540062"
  exit 1
fi

echo "✔️ Tumor Marker Test Code is the expected in test data"

echo "==== RUNNING TEST: close clinical data specific tests ===="
