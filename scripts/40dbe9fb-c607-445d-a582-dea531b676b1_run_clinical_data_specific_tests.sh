#!/bin/bash
echo "==== RUNNING TEST: start clinical data specific tests ===="

### every query is scoped to ${CODE}: the whole config.csv runs against a single
### database, so an unscoped count adds up rows from the other datasets. Tables
### carrying DatasetIdentifier are filtered directly, the rest are joined to
### CancerPatient, and identifiers already built as <dataset><patient>_... are
### scoped by construction.

CANCER_RELATED_PROCEDURE_CODE_QUERY=$(docker exec $POSTGRES_CONTAINER psql -U postgres -d eucaim-etl-db -t -c "SELECT procedureeucaim FROM eucaim_cdm_ingestion.cancerrelatedprocedure c where procedureidentifier='${CODE}test6_procedure2_tumor_1';" | xargs)
CANCER_RELATED_PROCEDURE_CODE="CLIN1001712"

if [ "$CANCER_RELATED_PROCEDURE_CODE_QUERY" != "$CANCER_RELATED_PROCEDURE_CODE" ]; then
  echo "❌ Not expected cancer related procedure code on patient test6"
  exit 1
fi

echo "✔️ Cancer related procedure code is the expected in test data"

BIRTH_SEX_QUERY=$(docker exec $POSTGRES_CONTAINER psql -U postgres -d eucaim-etl-db -t -c "SELECT birthsexeucaim FROM eucaim_cdm_ingestion.cancerpatient c where c.identifier='test7' and c.datasetidentifier='${CODE}';" | xargs)
BIRTH_SEX_CODE="COM1001370"

if [ "$BIRTH_SEX_QUERY" != "$BIRTH_SEX_CODE" ]; then
  echo "❌ Not expected birth sex code on patient test7"
  exit 1
fi

echo "✔️ Patient birth sex code is the expected in test data"

PATIENT_DIAGNOSTICCATEGORY_QUERY=$(docker exec $POSTGRES_CONTAINER psql -U postgres -d eucaim-etl-db -t -c "SELECT diagnosticcategoryeucaim FROM eucaim_cdm_ingestion.cancerpatient c where c.identifier='test7' and c.datasetidentifier='${CODE}';" | xargs)
PATIENT_DIAGNOSTICCATEGORY_CODE="COM1001087"

if [ "$PATIENT_DIAGNOSTICCATEGORY_QUERY" != "$PATIENT_DIAGNOSTICCATEGORY_CODE" ]; then
  echo "❌ Not expected patient diagnostic category code on patient test7"
  exit 1
fi

echo "✔️ Patient diagnostic category code is the expected in test data"

NUMBER_OF_EPISODES_QUERY=$(docker exec $POSTGRES_CONTAINER psql -U postgres -d eucaim-etl-db -t -c "SELECT COUNT(*) FROM eucaim_cdm_ingestion.Episode e where e.datasetidentifier='${CODE}';" | xargs)
NUMBER_OF_EPISODES=140

if [ "$NUMBER_OF_EPISODES_QUERY" -ne "$NUMBER_OF_EPISODES" ]; then
  echo "❌ Not expected number of episodes in sample data"
  exit 1
fi

echo "✔️ Number of episodes in test data is the expected"

HEALTH_STATUS_QUERY=$(docker exec $POSTGRES_CONTAINER psql -U postgres -d eucaim-etl-db -t -c "SELECT h.healthstatuseucaim FROM eucaim_cdm_ingestion.healthstatus h join eucaim_cdm_ingestion.cancerpatient p on p.identifier = h.patientidentifier and p.datasetidentifier='${CODE}' where h.identifier='40dbe9fb-c607-445d-a582-dea531b676b1test1_healthStatus1_tumor_1';" | xargs)
HEALTH_STATUS_CODE="CLIN1047414"

if [ "$HEALTH_STATUS_QUERY" != "$HEALTH_STATUS_CODE" ]; then
  echo "❌ Not expected health status code on patient test7"
  exit 1
fi

echo "✔️ Health status code is the expected in test data"

IMAGING_PROCEDURE_QUERY=$(docker exec $POSTGRES_CONTAINER psql -U postgres -d eucaim-etl-db -t -c "SELECT COUNT(*) FROM eucaim_cdm_ingestion.imagingprocedure i join eucaim_cdm_ingestion.cancerpatient p on p.identifier = i.patientidentifier and p.datasetidentifier='${CODE}' where i.patientidentifier='test1';" | xargs)
IMAGING_PROCEDURE_NUMBER=6

if [ "$IMAGING_PROCEDURE_QUERY" -ne "$IMAGING_PROCEDURE_NUMBER" ]; then
  echo "❌ Not expected number of imaging procedures for patient test1"
  exit 1
fi

echo "✔️ Number of imaging procedures for a patient is the expected in test data"

PCC_CODE_QUERY=$(docker exec $POSTGRES_CONTAINER psql -U postgres -d eucaim-etl-db -t -c "SELECT c.primarycancerconditioneucaim FROM eucaim_cdm_ingestion.primarycancercondition c join eucaim_cdm_ingestion.cancerpatient p on p.identifier = c.patientidentifier and p.datasetidentifier='${CODE}' where c.patientidentifier='test1';" | xargs)
PCC_CODE="CLIN1007990"

if [ "$PCC_CODE_QUERY" != "$PCC_CODE" ]; then
  echo "❌ Not expected PCC code on patient test1"
  exit 1
fi


echo "✔️ Primary Cancer Condition Code is the expected in test data"


RADIOTHERAPY_QUERY=$(docker exec $POSTGRES_CONTAINER psql -U postgres -d eucaim-etl-db -t -c "SELECT COUNT(*) FROM eucaim_cdm_ingestion.radiotherapycoursesummary r join eucaim_cdm_ingestion.cancerpatient p on p.identifier = r.patientidentifier and p.datasetidentifier='${CODE}';" | xargs)
RADIOTHERAPY_NUMBER=20

if [ "$RADIOTHERAPY_QUERY" -ne "$RADIOTHERAPY_NUMBER" ]; then
  echo "❌ Not expected number of radiotherapy procedures for test data"
  exit 1
fi

echo "✔️ Number of radiotherapy procedures is the expected in test data"

SURGICAL_PROCEDURE_CODE_QUERY=$(docker exec $POSTGRES_CONTAINER psql -U postgres -d eucaim-etl-db -t -c "SELECT procedureeucaim FROM eucaim_cdm_ingestion.surgicalprocedure c where treatmentidentifier='${CODE}test1_surgicalProcedure1_tumor_1';" | xargs)
SURGICAL_PROCEDURE_CODE="CLIN1004413"

if [ "$SURGICAL_PROCEDURE_CODE_QUERY" != "$SURGICAL_PROCEDURE_CODE" ]; then
  echo "❌ Not expected Surgical Procedure code on patient test1"
  exit 1
fi

echo "✔️ Surgical Procedure Code is the expected in test data"

TUMOR_LOCATION_CODE_QUERY=$(docker exec $POSTGRES_CONTAINER psql -U postgres -d eucaim-etl-db -t -c "SELECT bodysiteeucaim FROM eucaim_cdm_ingestion.tumor c where identifier='${CODE}test1_cancerCondition_1tumor_1';" | xargs)
TUMOR_LOCATION_CODE="BP1000051"

if [ "$TUMOR_LOCATION_CODE_QUERY" != "$TUMOR_LOCATION_CODE" ]; then
  echo "❌ Not expected Tumor Location code on patient test1"
  exit 1
fi

echo "✔️ Tumor Location Code is the expected in test data"

TUMOR_MARKER_TEST_CODE_QUERY=$(docker exec $POSTGRES_CONTAINER psql -U postgres -d eucaim-etl-db -t -c "SELECT tumormarkereucaim FROM eucaim_cdm_ingestion.tumormarkertest c where identifier='${CODE}test1_tumorMarkerTest_9tumor_1';" | xargs)
TUMOR_MARKER_TEST_CODE="CLIN1051952"

if [ "$TUMOR_MARKER_TEST_CODE_QUERY" != "$TUMOR_MARKER_TEST_CODE" ]; then
  echo "❌ Not expected Tumor Marker Test on patient test1"
  exit 1
fi

echo "✔️ Tumor Marker Test Code is the expected in test data"

echo "==== RUNNING TEST: close clinical data specific tests ===="
