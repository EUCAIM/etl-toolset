#!/bin/bash
# Runs the three data-quality SQL checks (ingestion, output, and the
# ingestion-vs-output comparison) against the running nifi-postgres
# container in one shot.
#
# Usage:
#   scripts/check_data.sh                    # every dataset
#   scripts/check_data.sh <dataset_id>       # scoped to one dataset

set -e
set -o pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS_DIR="$ROOT_DIR/scripts"
POSTGRES_CONTAINER=$(docker compose -f "$ROOT_DIR/docker-compose.yaml" ps -q nifi-postgres)

if [ -z "$POSTGRES_CONTAINER" ]; then
  echo "❌ nifi-postgres is not running (docker compose ps found nothing)"
  exit 1
fi

PSQL_ARGS=(-U postgres -d eucaim-etl-db)
if [ -n "$1" ]; then
  PSQL_ARGS+=(-v "dataset='$1'")
fi

for f in check_ingestion_data.sql check_output_data.sql check_ingestion_vs_output.sql; do
  echo ""
  echo "==== $f ===="
  docker exec -i "$POSTGRES_CONTAINER" psql "${PSQL_ARGS[@]}" -f - < "$SCRIPTS_DIR/$f"
done
