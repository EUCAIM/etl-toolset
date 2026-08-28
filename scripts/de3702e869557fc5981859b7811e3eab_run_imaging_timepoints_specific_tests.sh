#!/bin/bash

echo "==== RUNNING TEST: start imaging timepoints specific tests ===="
# Every study must reach the output CDM, which only happens when the timepoint
# links it to an ImagingProcedure. The KI mapping emits one procedure per
# patient at timepoint 1, so the sample keeps one study per patient at that
# timepoint and all of them are expected to link.
echo "Validating imaging studies linked into the output database..."
### scoped to ${CODE} through patient.dataset_id: image_study has no dataset
### column of its own and the whole config.csv shares one database
LINKED_STUDIES=$(docker exec $POSTGRES_CONTAINER psql -U postgres -d eucaim-etl-db -t -c "SELECT COUNT(*) FROM eucaim_cdm_output.image_study s join eucaim_cdm_output.patient p on p.patient_id = s.patient_id and p.dataset_id='${CODE}';" | xargs)

echo "Number of output rows in eucaim_cdm_output.image_study table: $LINKED_STUDIES  (Expected rows: $NUMBER_OF_STUDIES)"

if [ "$LINKED_STUDIES" -ne $NUMBER_OF_STUDIES ]; then
  echo "❌ Imaging studies did not link to an imaging procedure"
  exit 1
fi
echo "==== RUNNING TEST: close imaging timepoints specific tests ===="
