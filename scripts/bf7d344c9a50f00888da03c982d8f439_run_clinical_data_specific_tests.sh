#!/bin/bash

echo "==== RUNNING TEST: start clinical data specific tests ===="

### APHP IMALIVE: one row per patient, with at most one MRI and one CT (columns N and P are 1/0
### flags) and an optional surgery. The sample covers every combination of the two flags, a tie
### between the MRI and the CT dates (MOSAIC_0006) and a patient with no surgery (MOSAIC_0004).

imalive_query() {
  docker exec $POSTGRES_CONTAINER psql -U postgres -d eucaim-etl-db -t -c "$1" | xargs
}

imalive_expect() {
  local LABEL="$1" EXPECTED="$2" GOT="$3"
  if [ "$GOT" != "$EXPECTED" ]; then
    echo "❌ Not expected ${LABEL} (got '${GOT}', expected '${EXPECTED}')"
    exit 1
  fi
  echo "✔️ ${LABEL} is the expected in test data"
}

P1="MOSAIC_0001"
PCC1="${CODE}${P1}_cancerCondition_1"

imalive_expect "birth sex code on patient 1 (1 = male)" "COM1001366" \
  "$(imalive_query "SELECT birthsexeucaim FROM eucaim_cdm_ingestion.cancerpatient WHERE identifier='${P1}' AND datasetidentifier='${CODE}';")"

imalive_expect "birth sex code on patient 2 (0 = female)" "COM1001370" \
  "$(imalive_query "SELECT birthsexeucaim FROM eucaim_cdm_ingestion.cancerpatient WHERE identifier='MOSAIC_0002' AND datasetidentifier='${CODE}';")"

imalive_expect "diagnostic category code on patient 1" "COM1001087" \
  "$(imalive_query "SELECT diagnosticcategoryeucaim FROM eucaim_cdm_ingestion.cancerpatient WHERE identifier='${P1}' AND datasetidentifier='${CODE}';")"

imalive_expect "managing organization on patient 1" "AP-HP" \
  "$(imalive_query "SELECT managingorganization FROM eucaim_cdm_ingestion.cancerpatient WHERE identifier='${P1}' AND datasetidentifier='${CODE}';")"

imalive_expect "cancer condition code, morphology, age and asserted date on patient 1" \
  "CLIN1043447 | CLIN1049516 | 64.00 | 2012-09-21 | ${CODE}${P1}_pathologyProcedure_1" \
  "$(imalive_query "SELECT primarycancerconditioneucaim || ' | ' || histologymorphologybehavioureucaim || ' | ' || ageofdiagnosis || ' | ' || asserteddate || ' | ' || confirmedbyprocedure FROM eucaim_cdm_ingestion.primarycancercondition WHERE identifier='${PCC1}';")"

imalive_expect "tumor body site code on patient 1" "CLIN1063728" \
  "$(imalive_query "SELECT bodysiteeucaim FROM eucaim_cdm_ingestion.tumor WHERE primarycancerconditionidentifier='${PCC1}';")"

### columns J and L carry SNOMED codes until the hyperontology covers them
imalive_expect "pathology procedure (column J) on patient 1" "snomed:39228008 | 2012-09-21 | 1" \
  "$(imalive_query "SELECT procedureeucaim || ' | ' || performeddate || ' | ' || episode FROM eucaim_cdm_ingestion.cancerrelatedprocedure WHERE primarycancerconditionidentifier='${PCC1}';")"

imalive_expect "surgical procedure (column L) on patient 1" "snomed:71273005 | 2012-09-21 | 2" \
  "$(imalive_query "SELECT procedureeucaim || ' | ' || performeddate || ' | ' || episode FROM eucaim_cdm_ingestion.surgicalprocedure WHERE patientidentifier='${P1}' AND treatmentidentifier LIKE '${CODE}%';")"

imalive_expect "number of surgical procedures (patient 4 has none)" "7" \
  "$(imalive_query "SELECT COUNT(*) FROM eucaim_cdm_ingestion.surgicalprocedure WHERE treatmentidentifier LIKE '${CODE}%';")"

### columns N and P: an imaging procedure only where the flag is 1, numbered by date per patient
imalive_expect "number of imaging procedures (5 MRI + 6 CT)" "11" \
  "$(imalive_query "SELECT COUNT(*) FROM eucaim_cdm_ingestion.imagingprocedure WHERE procedureidentifier LIKE '${CODE}%';")"

for EXPECTED in "MOSAIC_0001|CT:1:snomed:169070004,MRI:2:snomed:241622002" \
                "MOSAIC_0002|MRI:1:snomed:241622002" \
                "MOSAIC_0003|CT:1:snomed:169070004" \
                "MOSAIC_0004|" \
                "MOSAIC_0005|MRI:1:snomed:241622002,CT:2:snomed:169070004" \
                "MOSAIC_0006|MRI:1:snomed:241622002,CT:2:snomed:169070004"; do
  PATIENT_ID="${EXPECTED%%|*}"
  imalive_expect "imaging procedures and timepoints of ${PATIENT_ID}" "${EXPECTED##*|}" \
    "$(imalive_query "SELECT string_agg(imagingprocedureoriginal || ':' || imagingtimepoint || ':' || imagingprocedureeucaim, ',' ORDER BY imagingtimepoint) FROM eucaim_cdm_ingestion.imagingprocedure WHERE primarycancerconditionidentifier='${CODE}${PATIENT_ID}_cancerCondition_1';")"
done

imalive_expect "imaging procedure category and date of the MRI of patient 1" "IMG1005453 | 2012-08-21" \
  "$(imalive_query "SELECT imagingprocedurecategorycodeeucaim || ' | ' || performeddate FROM eucaim_cdm_ingestion.imagingprocedure WHERE procedureidentifier='${CODE}${P1}_imagingProcedure_MRI';")"

imalive_expect "number of episodes in sample data" "16" \
  "$(imalive_query "SELECT COUNT(*) FROM eucaim_cdm_ingestion.episode WHERE datasetidentifier='${CODE}';")"

imalive_expect "coded values left as NOT FOUND" "0" \
  "$(imalive_query "SELECT COUNT(*) FROM eucaim_cdm_ingestion.mappedcodeableconceptsresults WHERE datasetid='${CODE}' AND codeineucaim = 'NOT FOUND';")"

echo "==== RUNNING TEST: close clinical data specific tests ===="
