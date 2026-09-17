#!/bin/bash
echo "==== RUNNING TEST: start clinical data specific tests ===="

### this mapping builds its identifiers as <patient>_..., without the dataset
### code in front, so every query is joined up to CancerPatient to keep it
### scoped to ${CODE}: the whole config.csv runs against a single database.

PATIENT='EUCAIM-150022517598238127341798225763196953189'

### the two episodes of the model: diagnosis at time 0 and the CAR-T treatment
EPISODE_QUERY=$(docker exec $POSTGRES_CONTAINER psql -U postgres -d eucaim-etl-db -t -c "SELECT COUNT(*) FROM eucaim_cdm_ingestion.episode WHERE patientidentifier='${PATIENT}' AND datasetidentifier='${CODE}';" | xargs)
EPISODE_NUMBER=2

if [ "$EPISODE_QUERY" -ne "$EPISODE_NUMBER" ]; then
  echo "❌ Not expected number of episodes for patient $PATIENT"
  exit 1
fi

echo "✔️ Diagnosis and treatment episodes are created"

### the three PET-CT studies: before the infusion and at 1 and 3 months
IMAGING_PROCEDURE_QUERY=$(docker exec $POSTGRES_CONTAINER psql -U postgres -d eucaim-etl-db -t -c "SELECT COUNT(*) FROM eucaim_cdm_ingestion.imagingprocedure i JOIN eucaim_cdm_ingestion.cancerpatient p ON p.identifier = i.patientidentifier AND p.datasetidentifier='${CODE}' WHERE i.patientidentifier='${PATIENT}';" | xargs)
IMAGING_PROCEDURE_NUMBER=3

if [ "$IMAGING_PROCEDURE_QUERY" -ne "$IMAGING_PROCEDURE_NUMBER" ]; then
  echo "❌ Not expected number of imaging procedures for patient $PATIENT"
  exit 1
fi

echo "✔️ Number of imaging procedures for a patient is the expected in test data"

### this dataset reaches offsets of thousands of days, which is what forced
### OffsetFromDiagnosis to be widened beyond DECIMAL(5,2): if the column is
### still the narrow one the row never lands and this count comes back as 0
LONG_OFFSET_QUERY=$(docker exec $POSTGRES_CONTAINER psql -U postgres -d eucaim-etl-db -t -c "SELECT COUNT(*) FROM eucaim_cdm_ingestion.imagingprocedure i JOIN eucaim_cdm_ingestion.cancerpatient p ON p.identifier = i.patientidentifier AND p.datasetidentifier='${CODE}' WHERE i.patientidentifier='${PATIENT}' AND i.offsetfromdiagnosis > 999;" | xargs)
LONG_OFFSET_NUMBER=3

if [ "$LONG_OFFSET_QUERY" -ne "$LONG_OFFSET_NUMBER" ]; then
  echo "❌ Offsets beyond 999 days were not stored for patient $PATIENT"
  exit 1
fi

echo "✔️ Offsets beyond 999 days are stored without overflow"

### one index tumor per episode plus one row per involvement listed in the
### ';'-separated column: 3 involvements at diagnosis and 1 before CAR-T
TUMOR_QUERY=$(docker exec $POSTGRES_CONTAINER psql -U postgres -d eucaim-etl-db -t -c "SELECT COUNT(*) FROM eucaim_cdm_ingestion.tumor t JOIN eucaim_cdm_ingestion.primarycancercondition c ON c.identifier = t.primarycancerconditionidentifier JOIN eucaim_cdm_ingestion.cancerpatient p ON p.identifier = c.patientidentifier AND p.datasetidentifier='${CODE}' WHERE c.patientidentifier='${PATIENT}';" | xargs)
TUMOR_NUMBER=6

if [ "$TUMOR_QUERY" -ne "$TUMOR_NUMBER" ]; then
  echo "❌ Not expected number of tumor rows for patient $PATIENT"
  exit 1
fi

echo "✔️ Multi-valued tumor involvement is split into one row per site"

### the CAR-T product is persisted even though the hyperontology has no concept
### for it yet: the original value must be there and the EUCAIM code must not
### be invented
MEDICATION_QUERY=$(docker exec $POSTGRES_CONTAINER psql -U postgres -d eucaim-etl-db -t -c "SELECT medicationcodeoriginal FROM eucaim_cdm_ingestion.cancerrelatedmedication m JOIN eucaim_cdm_ingestion.cancerpatient p ON p.identifier = m.patientidentifier AND p.datasetidentifier='${CODE}' WHERE m.patientidentifier='${PATIENT}';" | xargs)
MEDICATION_CODE='Tisagenlecleucel'

if [ "$MEDICATION_QUERY" != "$MEDICATION_CODE" ]; then
  echo "❌ Not expected CAR-T product on patient $PATIENT"
  exit 1
fi

echo "✔️ CAR-T product is stored with its original value"

### a patient whose 3-month evaluation is NA must produce two studies, not three
PATIENT_NA='EUCAIM-90719333099368965402437184739625970359'
NA_QUERY=$(docker exec $POSTGRES_CONTAINER psql -U postgres -d eucaim-etl-db -t -c "SELECT COUNT(*) FROM eucaim_cdm_ingestion.imagingprocedure i JOIN eucaim_cdm_ingestion.cancerpatient p ON p.identifier = i.patientidentifier AND p.datasetidentifier='${CODE}' WHERE i.patientidentifier='${PATIENT_NA}';" | xargs)
NA_NUMBER=2

if [ "$NA_QUERY" -ne "$NA_NUMBER" ]; then
  echo "❌ A missing evaluation study was not skipped for patient $PATIENT_NA"
  exit 1
fi

echo "✔️ Missing evaluation studies are skipped instead of stored empty"

echo "==== RUNNING TEST: close clinical data specific tests ===="
