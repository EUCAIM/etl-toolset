#!/bin/bash

echo "==== RUNNING TEST: start clinical data specific tests ===="
NUMBER_OF_STUDIES=3
# Every study must reach the output CDM, which only happens when the timepoint
# links it to an ImagingProcedure. The KI mapping emits one procedure per
# patient at timepoint 1, so the sample keeps one study per patient at that
# timepoint and all of them are expected to link.
echo "Validating imaging studies linked into the output database..."
LINKED_STUDIES=$(docker exec $POSTGRES_CONTAINER psql -U postgres -d eucaim-etl-db -t -c "SELECT COUNT(*) FROM eucaim_cdm_output.image_study;" | xargs)

echo "Number of output rows in eucaim_cdm_output.image_study table: $LINKED_STUDIES  (Expected rows: $NUMBER_OF_STUDIES)"

if [ "$LINKED_STUDIES" -ne $NUMBER_OF_STUDIES ]; then
echo "❌ Imaging studies did not link to an imaging procedure"
exit 1
fi
echo "==== RUNNING TEST: close clinical data specific tests ===="