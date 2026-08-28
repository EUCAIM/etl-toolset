#!/bin/bash

echo "==== RUNNING TEST: start clinical data specific tests ===="

CANCER_RELATED_MEDICATION_EPISODE_QUERY=$(docker exec $POSTGRES_CONTAINER psql -U postgres -d eucaim-etl-db -t -c "SELECT episode FROM eucaim_cdm_ingestion.cancerrelatedmedication c where treatmentidentifier='${CODE}EUCAIM-42359961463279617395233496226407435633_Medication2_tumor_1';" | xargs)
CANCER_RELATED_MEDICATION_EPISODE=4

if [ "$CANCER_RELATED_MEDICATION_EPISODE_QUERY" != "$CANCER_RELATED_MEDICATION_EPISODE" ]; then
  echo "❌ Not expected cancer related medication episode on patient 1"
  exit 1
fi

echo "✔️ Cancer related procedure code is the expected in test data"

BIRTH_SEX_QUERY=$(docker exec $POSTGRES_CONTAINER psql -U postgres -d eucaim-etl-db -t -c "SELECT birthsexeucaim FROM eucaim_cdm_ingestion.cancerpatient c where c.identifier='EUCAIM-42359961463279617395233496226407435633' and c.datasetidentifier='${CODE}';" | xargs)
BIRTH_SEX_CODE="COM1001370"

if [ "$BIRTH_SEX_QUERY" != "$BIRTH_SEX_CODE" ]; then
  echo "❌ Not expected birth sex code on patient 1"
  exit 1
fi

echo "✔️ Patient birth sex code is the expected in test data"

PATIENT_DIAGNOSTICCATEGORY_QUERY=$(docker exec $POSTGRES_CONTAINER psql -U postgres -d eucaim-etl-db -t -c "SELECT diagnosticcategoryeucaim FROM eucaim_cdm_ingestion.cancerpatient c where c.identifier='EUCAIM-42359961463279617395233496226407435633' and c.datasetidentifier='${CODE}';" | xargs)
PATIENT_DIAGNOSTICCATEGORY_CODE="CLIN1007988"

if [ "$PATIENT_DIAGNOSTICCATEGORY_QUERY" != "$PATIENT_DIAGNOSTICCATEGORY_CODE" ]; then
  echo "❌ Not expected patient diagnostic category code on patient 1"
  exit 1
fi

echo "✔️ Patient diagnostic category code is the expected in test data"

NUMBER_OF_EPISODES_QUERY=$(docker exec $POSTGRES_CONTAINER psql -U postgres -d eucaim-etl-db -t -c "SELECT COUNT(*) FROM eucaim_cdm_ingestion.Episode e where e.datasetidentifier='${CODE}';" | xargs)
NUMBER_OF_EPISODES=8

if [ "$NUMBER_OF_EPISODES_QUERY" -ne "$NUMBER_OF_EPISODES" ]; then
  echo "❌ Not expected number of episodes in sample data"
  exit 1
fi

echo "✔️ Number of episodes in test data is the expected"

IMAGING_PROCEDURE_QUERY=$(docker exec $POSTGRES_CONTAINER psql -U postgres -d eucaim-etl-db -t -c "SELECT COUNT(*) FROM eucaim_cdm_ingestion.imagingprocedure i join eucaim_cdm_ingestion.cancerpatient p on p.identifier = i.patientidentifier and p.datasetidentifier='${CODE}' where i.patientidentifier='EUCAIM-42359961463279617395233496226407435633';" | xargs)
IMAGING_PROCEDURE_NUMBER=1

if [ "$IMAGING_PROCEDURE_QUERY" -ne "$IMAGING_PROCEDURE_NUMBER" ]; then
  echo "❌ Not expected number of imaging procedures for patient EUCAIM-42359961463279617395233496226407435633"
  exit 1
fi

echo "✔️ Number of imaging procedures for a patient is the expected in test data"

PCC_CODE_QUERY=$(docker exec $POSTGRES_CONTAINER psql -U postgres -d eucaim-etl-db -t -c "SELECT c.primarycancerconditioneucaim FROM eucaim_cdm_ingestion.primarycancercondition c join eucaim_cdm_ingestion.cancerpatient p on p.identifier = c.patientidentifier and p.datasetidentifier='${CODE}' where c.patientidentifier='EUCAIM-42359961463279617395233496226407435633';" | xargs)
PCC_CODE="CLIN1007990"

if [ "$PCC_CODE_QUERY" != "$PCC_CODE" ]; then
  echo "❌ Not expected PCC code on patient EUCAIM-42359961463279617395233496226407435633"
  exit 1
fi


echo "✔️ Primary Cancer Condition Code is the expected in test data"


RADIOTHERAPY_QUERY=$(docker exec $POSTGRES_CONTAINER psql -U postgres -d eucaim-etl-db -t -c "SELECT COUNT(*) FROM eucaim_cdm_ingestion.radiotherapycoursesummary r join eucaim_cdm_ingestion.cancerpatient p on p.identifier = r.patientidentifier and p.datasetidentifier='${CODE}';" | xargs)
RADIOTHERAPY_NUMBER=2

if [ "$RADIOTHERAPY_QUERY" -ne "$RADIOTHERAPY_NUMBER" ]; then
  echo "❌ Not expected number of radiotherapy procedures for test data"
  exit 1
fi

echo "✔️ Number of radiotherapy procedures is the expected in test data"

SURGICAL_PROCEDURE_CODE_QUERY=$(docker exec $POSTGRES_CONTAINER psql -U postgres -d eucaim-etl-db -t -c "SELECT procedureeucaim FROM eucaim_cdm_ingestion.surgicalprocedure c where treatmentidentifier='${CODE}EUCAIM-235865861987234915500053222799778009958_surgicalProcedure1_tumor_1';" | xargs)
SURGICAL_PROCEDURE_CODE="CLIN1001712"

if [ "$SURGICAL_PROCEDURE_CODE_QUERY" != "$SURGICAL_PROCEDURE_CODE" ]; then
  echo "❌ Not expected Surgical Procedure code on patient 1"
  exit 1
fi

echo "✔️ Surgical Procedure Code is the expected in test data"

TUMOR_LOCATION_CODE_QUERY=$(docker exec $POSTGRES_CONTAINER psql -U postgres -d eucaim-etl-db -t -c "SELECT bodysitelocationqualifiereucaim FROM eucaim_cdm_ingestion.tumor c where identifier='${CODE}EUCAIM-235865861987234915500053222799778009958_cancerCondition_1tumor_1';" | xargs)
TUMOR_LOCATION_CODE="BP1000350"

if [ "$TUMOR_LOCATION_CODE_QUERY" != "$TUMOR_LOCATION_CODE" ]; then
  echo "❌ Not expected Tumor Location code on patient 2"
  exit 1
fi

echo "✔️ Tumor Location Code is the expected in test data"

echo "==== RUNNING TEST: close clinical data specific tests ===="