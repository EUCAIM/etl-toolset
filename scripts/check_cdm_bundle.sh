#!/bin/bash
# Checks the CDM CSV bundles in output_data/cdm against the database they came
# from. Three things are verified for every dataset with a manifest:
#
#   1. the manifest says complete, so the bundle is not a half written one
#   2. every CSV header is, column for column and in order, the header of its
#      table in eucaim_cdm_output. This is the contract that keeps the files
#      aligned with the CDM: a column renamed in the schema and not in the
#      export surfaces here instead of reaching a consumer
#   3. the rows in each CSV match both the manifest and the database
#
# Usage:
#   scripts/check_cdm_bundle.sh                  # every bundle found
#   scripts/check_cdm_bundle.sh <dataset_id>     # just this one
#
# POSTGRES_CONTAINER can be set to check against a container other than the
# nifi-postgres of this compose project.

set -o pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CDM_DIR="$ROOT_DIR/output_data/cdm"

if [ -z "$POSTGRES_CONTAINER" ]; then
  POSTGRES_CONTAINER=$(docker compose -f "$ROOT_DIR/docker-compose.yaml" ps -q nifi-postgres)
fi
if [ -z "$POSTGRES_CONTAINER" ]; then
  echo "❌ nifi-postgres is not running, and POSTGRES_CONTAINER is not set"
  exit 1
fi

psql_q() { docker exec "$POSTGRES_CONTAINER" psql -U postgres -d eucaim-etl-db -tAc "$1"; }

if [ -n "$1" ]; then
  MANIFESTS="$CDM_DIR/$1__manifest.csv"
  [ -f "$MANIFESTS" ] || { echo "❌ no bundle for dataset $1 in $CDM_DIR"; exit 1; }
else
  MANIFESTS=$(find "$CDM_DIR" -maxdepth 1 -type f -name '*__manifest.csv' | sort)
  [ -n "$MANIFESTS" ] || { echo "❌ no bundle found in $CDM_DIR"; exit 1; }
fi

FAILED=0

for manifest in $MANIFESTS; do
  dataset=$(basename "$manifest" __manifest.csv)
  ### per dataset, so one bad bundle does not hide the verdict of the next
  DS_FAILED=0
  echo ""
  echo "==== $dataset ===="

  status=$(tail -n +2 "$manifest" | cut -d',' -f3 | sort -u | tr '\n' ' ' | xargs)
  if [ "$status" != "complete" ]; then
    echo "  ❌ manifest status is '$status', the bundle is not complete"
    FAILED=1; DS_FAILED=1
    continue
  fi
  echo "  manifest: complete, $(($(wc -l < "$manifest") - 1)) tables"

  while IFS=',' read -r _ _ _ table manifest_rows; do
    [ -n "$table" ] || continue
    file="$CDM_DIR/${dataset}__${table}.csv"

    ### the database is asked in both branches: it is what decides whether the
    ### manifest itself is telling the truth
    db_rows=$(psql_q "SELECT count(*) FROM eucaim_cdm_output.v_export_$table WHERE export_dataset_id = '$dataset';")

    if [ ! -f "$file" ]; then
      ### no file is the right answer for a table with no rows, and only then
      if [ "$manifest_rows" != "0" ] || [ "$db_rows" != "0" ]; then
        echo "  ❌ $table: no file, but manifest=$manifest_rows db=$db_rows"
        FAILED=1; DS_FAILED=1
      fi
      continue
    fi

    ### the header the CDM says this table must have
    expected=$(psql_q "SELECT string_agg(column_name, ',' ORDER BY ordinal_position)
                       FROM information_schema.columns
                       WHERE table_schema = 'eucaim_cdm_output' AND table_name = '$table';")
    actual=$(head -1 "$file" | tr -d '\r')
    if [ "$actual" != "$expected" ]; then
      echo "  ❌ $table: header does not match eucaim_cdm_output.$table"
      echo "       csv: $actual"
      echo "       cdm: $expected"
      FAILED=1; DS_FAILED=1
      continue
    fi

    ### rows in the file, in the manifest and in the database must agree. A file
    ### that is present while the manifest says zero is a leftover of an earlier
    ### run; it is only harmless as long as it holds nothing but its header, and
    ### a stale one still full of rows is the worst thing this check can find
    csv_rows=$(($(wc -l < "$file") - 1))
    if [ "$csv_rows" != "$manifest_rows" ] || [ "$csv_rows" != "$db_rows" ]; then
      if [ "$manifest_rows" = "0" ] && [ "$db_rows" = "0" ]; then
        echo "  ❌ $table: stale file, it still holds $csv_rows rows the database no longer has"
      else
        echo "  ❌ $table: csv=$csv_rows manifest=$manifest_rows db=$db_rows"
      fi
      FAILED=1; DS_FAILED=1
    fi
  done < <(tail -n +2 "$manifest")

  ### a file nobody declared means a table left the CDM and its old export was
  ### never cleaned up. Tables the manifest declares at zero rows are declared,
  ### so an emptied leftover of theirs is caught above, not here
  for file in "$CDM_DIR/${dataset}__"*.csv; do
    table=$(basename "$file" .csv); table=${table#${dataset}__}
    [ "$table" = "manifest" ] && continue
    grep -q ",$table," "$manifest" || { echo "  ❌ $table: file present but not in the manifest"; FAILED=1; DS_FAILED=1; }
  done

  [ $DS_FAILED -eq 0 ] && echo "  ✅ headers, counts and manifest agree"
done

echo ""
if [ $FAILED -ne 0 ]; then
  echo "❌ the bundle does not match the database"
  exit 1
fi
echo "✅ every bundle matches eucaim_cdm_output"
