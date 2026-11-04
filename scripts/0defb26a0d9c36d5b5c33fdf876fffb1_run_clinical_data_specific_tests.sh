#!/bin/bash

echo "==== RUNNING TEST: start clinical data specific tests ===="

### APHP PAIMRI: one CSV per CDM entity, related by ids and joined by JoinRelationalCSVs. The
### sample has two patients with cancer (90001, 90004) and two without (90002 negative screening,
### 90003 screening), whose MRI and biopsies are left out: ingestion needs a cancer condition for
### them. Every coded value is a hyperontology term, so all of them must resolve.

paimri_query() {
  docker exec $POSTGRES_CONTAINER psql -U postgres -d eucaim-etl-db -t -c "$1" | xargs
}

paimri_expect() {
  local LABEL="$1" EXPECTED="$2" GOT="$3"
  if [ "$GOT" != "$EXPECTED" ]; then
    echo "❌ Not expected ${LABEL} (got '${GOT}', expected '${EXPECTED}')"
    exit 1
  fi
  echo "✔️ ${LABEL} is the expected in test data"
}

P1="90001"
PCC1="${CODE}${P1}_cancerCondition_1"

paimri_expect "birth sex, birth date and managing organization on patient 1" \
  "COM1001366 | Male | 1960-03-15 | Tenon Hospital" \
  "$(paimri_query "SELECT birthsexeucaim || ' | ' || birthsexoriginal || ' | ' || birthdate || ' | ' || managingorganization FROM eucaim_cdm_ingestion.cancerpatient WHERE identifier='${P1}' AND datasetidentifier='${CODE}';")"

paimri_expect "diagnostic category of the negative screening (patient 2)" "COM1002626" \
  "$(paimri_query "SELECT diagnosticcategoryeucaim FROM eucaim_cdm_ingestion.cancerpatient WHERE identifier='90002' AND datasetidentifier='${CODE}';")"

paimri_expect "cancer condition code, morphology, age, asserted date, confirming biopsy and episode on patient 1" \
  "CLIN1000075 | CLIN1047138 | 62.00 | 2023-02-01 | ${CODE}${P1}_procedure_2 | 1" \
  "$(paimri_query "SELECT primarycancerconditioneucaim || ' | ' || histologymorphologybehavioureucaim || ' | ' || ageofdiagnosis || ' | ' || asserteddate || ' | ' || confirmedbyprocedure || ' | ' || episodenumber FROM eucaim_cdm_ingestion.primarycancercondition WHERE identifier='${PCC1}';")"

paimri_expect "number of cancer conditions" "2" \
  "$(paimri_query "SELECT COUNT(*) FROM eucaim_cdm_ingestion.primarycancercondition WHERE identifier LIKE '${CODE}%';")"

### the MRI of patients 2 and 3 have no cancer condition to hang from
paimri_expect "number of imaging procedures (patients without cancer left out)" "2" \
  "$(paimri_query "SELECT COUNT(*) FROM eucaim_cdm_ingestion.imagingprocedure WHERE procedureidentifier LIKE '${CODE}%';")"

### the offset comes from the dates, not from the 0 of the source: 2023-01-10 is 22 days before 2023-02-01
paimri_expect "MRI of patient 1: code, category, date, timepoint, offset and its unit" \
  "IMG1005507 | IMG1005453 | 2023-01-10 | 1 | -22.00 | COM1000153 | ${PCC1}" \
  "$(paimri_query "SELECT imagingprocedureeucaim || ' | ' || imagingprocedurecategorycodeeucaim || ' | ' || performeddate || ' | ' || imagingtimepoint || ' | ' || offsetfromdiagnosis || ' | ' || offsetuniteucaim || ' | ' || primarycancerconditionidentifier FROM eucaim_cdm_ingestion.imagingprocedure WHERE procedureidentifier='${CODE}${P1}_imagingProcedure_1';")"

paimri_expect "number of diagnostic procedures (biopsies of patients with cancer)" "3" \
  "$(paimri_query "SELECT COUNT(*) FROM eucaim_cdm_ingestion.cancerrelatedprocedure WHERE procedureidentifier LIKE '${CODE}%';")"

paimri_expect "systematic biopsy of patient 1: code, category, date and offset" \
  "CLIN1001934 | CLIN1004413 | 2023-02-01 | 0.00 | 1" \
  "$(paimri_query "SELECT procedureeucaim || ' | ' || procedurecategorycodeeucaim || ' | ' || performeddate || ' | ' || offsetfromdiagnosis || ' | ' || episode FROM eucaim_cdm_ingestion.cancerrelatedprocedure WHERE procedureidentifier='${CODE}${P1}_procedure_3';")"

### the tumor reaches its condition through its histologic grade and its site through Body_Site;
### its morphology carries a comma inside quotes in the source
paimri_expect "tumor of patient 1: site, location, laterality, grade, morphology, size method and size" \
  "BP1000021 | BP1000167 | IMG1016670 | COM1001343 | CLIN1047138 | CLIN1035079 | 14.00 | ${PCC1}" \
  "$(paimri_query "SELECT bodysiteeucaim || ' | ' || bodysitelocationqualifiereucaim || ' | ' || bodysitelateralityqualifiereucaim || ' | ' || histologicgradeeucaim || ' | ' || morphologyeucaim || ' | ' || sizemethodeucaim || ' | ' || sizemaximumdimension || ' | ' || primarycancerconditionidentifier FROM eucaim_cdm_ingestion.tumor WHERE identifier='${CODE}${P1}_tumor_1';")"

paimri_expect "number of tumors" "2" \
  "$(paimri_query "SELECT COUNT(*) FROM eucaim_cdm_ingestion.tumor WHERE identifier LIKE '${CODE}%';")"

paimri_expect "histologic grade of patient 4: grade, scoring system and condition" \
  "COM1001341 | CLIN1037294 | ${CODE}90004_cancerCondition_2" \
  "$(paimri_query "SELECT gradeeucaim || ' | ' || scoringsystemeucaim || ' | ' || primarycancerconditionidentifier FROM eucaim_cdm_ingestion.histologicgrade WHERE identifier='${CODE}90004_histologicGrade_2';")"

### tumor marker tests only need the patient, so those of patients without cancer are kept
paimri_expect "number of tumor marker tests" "10" \
  "$(paimri_query "SELECT COUNT(*) FROM eucaim_cdm_ingestion.tumormarkertest WHERE identifier LIKE '${CODE}%';")"

paimri_expect "first PSA of patient 1: marker, category, value, unit, date and episode" \
  "CLIN1030627 | GEN1000022 | 8.200 | COM1000156 | 2023-01-10 | 1" \
  "$(paimri_query "SELECT tumormarkereucaim || ' | ' || categoryeucaim || ' | ' || valueasnumber || ' | ' || valueasconceptuniteucaim || ' | ' || dateofmarker || ' | ' || episode FROM eucaim_cdm_ingestion.tumormarkertest WHERE identifier='${CODE}${P1}_tumorMarkerTest_1';")"

paimri_expect "number of episodes and their type" "4 | GEN1000008" \
  "$(paimri_query "SELECT COUNT(*) || ' | ' || string_agg(DISTINCT typeeucaim, ',') FROM eucaim_cdm_ingestion.episode WHERE datasetidentifier='${CODE}';")"

paimri_expect "coded values left as NOT FOUND" "0" \
  "$(paimri_query "SELECT COUNT(*) FROM eucaim_cdm_ingestion.mappedcodeableconceptsresults WHERE datasetid='${CODE}' AND codeineucaim = 'NOT FOUND';")"

echo "==== RUNNING TEST: close clinical data specific tests ===="
