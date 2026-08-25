#!/bin/bash
echo "==== RUNNING TEST: processing imaging metadata sample ===="

IMAGING_PROCEDURE_QUERY=$(docker exec $POSTGRES_CONTAINER psql -U postgres -d eucaim-etl-db -t -c "SELECT COUNT(*) FROM eucaim_cdm_ingestion.imagingprocedure c where patientidentifier='EUCAIM-122786961168182220732412405780701540062';" | xargs)
IMAGING_PROCEDURE_NUMBER=2

if [ "$IMAGING_PROCEDURE_QUERY" -ne "$IMAGING_PROCEDURE_NUMBER" ]; then
  echo "❌ Not expected number of imaging procedures for patient EUCAIM-122786961168182220732412405780701540062"
  exit 1
fi

echo "✔️ Number of imaging procedures for a patient is the expected in test data"


SURGICAL_PROCEDURE_CODE_QUERY=$(docker exec $POSTGRES_CONTAINER psql -U postgres -d eucaim-etl-db -t -c "SELECT procedureeucaim FROM eucaim_cdm_ingestion.surgicalprocedure c where id=2;" | xargs)
SURGICAL_PROCEDURE_CODE="CLIN1001712"

if [ "$SURGICAL_PROCEDURE_CODE_QUERY" != "$SURGICAL_PROCEDURE_CODE" ]; then
  echo "❌ Not expected Surgical Procedure code on patient EUCAIM-122786961168182220732412405780701540062"
  exit 1
fi

echo "✔️ Surgical Procedure Code is the expected in test data"

TUMOR_MARKER_TEST_CODE_QUERY=$(docker exec $POSTGRES_CONTAINER psql -U postgres -d eucaim-etl-db -t -c "SELECT tumormarkereucaim FROM eucaim_cdm_ingestion.tumormarkertest c where id=4;" | xargs)
TUMOR_MARKER_TEST_CODE="CLIN1044953"

if [ "$TUMOR_MARKER_TEST_CODE_QUERY" != "$TUMOR_MARKER_TEST_CODE" ]; then
  echo "❌ Not expected Tumor Marker Test on patient EUCAIM-122786961168182220732412405780701540062"
  exit 1
fi

echo "✔️ Tumor Marker Test Code is the expected in test data"

