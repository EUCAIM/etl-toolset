#!/bin/bash
###
### Applies again, over the running nifi-postgres, the Database/*.sql files that hold
### reference data and code, so a node deployed from an earlier commit can pick up new lookup
### values, ontology concepts or procedures WITHOUT recreating the database. Postgres runs
### Database/*.sql only the first time its volume is initialised, so after a `git pull` those
### changes never reach an existing database by themselves.
###
### What it reloads, in the order the first-time initialisation uses:
###
###   aux          4_init_eucaim_etl_aux.sql      the Lookup* tables the flows read.
###                                               Each one is dropped and filled again.
###   procedures   6, 7, 7a, 7b, 7c               CREATE OR REPLACE of the procedures and
###                                               export views. No data is touched.
###   ontology     1, 5_patch, 5_update, 5z       the hyperontology concept tables. Dropped
###                                               and loaded again: slower (several MB).
###
### It never touches the ingestion and output schemas (2, 3, 3z) or the init flag (8): they
### hold the data the ETL has produced.
###
### The default is `aux procedures`. Every selected group is applied in ONE transaction, so
### an error leaves the database as it was.
###
### Any row someone added by hand to a Lookup* table, or any change to the concept tables
### made outside these files, is lost: put it in the SQL files first. --backup writes a dump
### of the schemas about to be replaced.
###
### NiFi needs no restart for SQL changes: the database lookup services do not cache. A
### change to a Groovy script or to a flow does need the flows to be loaded again.
###
### Usage:
###   scripts/reload_database.sh                      # aux + procedures
###   scripts/reload_database.sh aux                  # only the lookup tables
###   scripts/reload_database.sh ontology             # only the concept tables
###   scripts/reload_database.sh all                  # the three groups
###   scripts/reload_database.sh --backup aux         # dump the schemas first
###   scripts/reload_database.sh --dry-run all        # list the files, apply nothing
###

set -e
set -o pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DB_DIR="$ROOT_DIR/Database"

BACKUP=0
DRY_RUN=0
GROUPS_WANTED=()

for arg in "$@"; do
  case "$arg" in
    --backup)  BACKUP=1 ;;
    --dry-run) DRY_RUN=1 ;;
    aux|procedures|ontology) GROUPS_WANTED+=("$arg") ;;
    all)       GROUPS_WANTED+=(aux procedures ontology) ;;
    -h|--help) sed -n '2,/^$/p' "${BASH_SOURCE[0]}" | sed 's/^### \{0,1\}//'; exit 0 ;;
    *) echo "❌ unknown argument: $arg (try --help)"; exit 2 ;;
  esac
done
[ ${#GROUPS_WANTED[@]} -eq 0 ] && GROUPS_WANTED=(aux procedures)

has_group() { local g; for g in "${GROUPS_WANTED[@]}"; do [ "$g" = "$1" ] && return 0; done; return 1; }

### files in the order initdb.d would run them (alphabetical), restricted to the groups asked
FILES=()
has_group ontology   && FILES+=(1_init_eucaim_hyperontology_codes.sql)
has_group aux        && FILES+=(4_init_eucaim_etl_aux.sql)
has_group ontology   && FILES+=(5_init_eucaim_hyperontology_codes_patch.sql 5_init_eucaim_hyperontology_codes_update.sql 5z_dedup_eucaim_hyperontology_concept.sql)
has_group procedures && FILES+=(6_procedure_update_output_db_for_dataset.sql 7_procedure__log_db.sql 7a_init_eucaim_cdm_output_export_views.sql 7b_procedure_export_dataset_to_csv.sql 7c_procedure_report_dataset.sql)

for f in "${FILES[@]}"; do
  [ -f "$DB_DIR/$f" ] || { echo "❌ $DB_DIR/$f not found"; exit 1; }
done

echo "Groups: ${GROUPS_WANTED[*]}"
printf '  %s\n' "${FILES[@]}"
if [ "$DRY_RUN" -eq 1 ]; then echo "(dry run: nothing applied)"; exit 0; fi

POSTGRES_CONTAINER=$(docker compose -f "$ROOT_DIR/docker-compose.yaml" ps -q nifi-postgres 2>/dev/null || true)
[ -z "$POSTGRES_CONTAINER" ] && POSTGRES_CONTAINER=$(docker ps --filter "name=^/nifi-postgres$" --format "{{.ID}}" | head -n1)
if [ -z "$POSTGRES_CONTAINER" ]; then
  echo "❌ nifi-postgres is not running"
  exit 1
fi

PSQL=(docker exec -i "$POSTGRES_CONTAINER" psql -U postgres -d eucaim-etl-db -v ON_ERROR_STOP=1 -q)

if [ "$BACKUP" -eq 1 ]; then
  DUMP_ARGS=()
  has_group aux      && DUMP_ARGS+=(-n eucaim_etl_aux)
  has_group ontology && DUMP_ARGS+=(-n eucaim_hyperontology_codes)
  if [ ${#DUMP_ARGS[@]} -gt 0 ]; then
    BACKUP_FILE="$ROOT_DIR/reload_backup_$(date +%Y%m%d_%H%M%S).sql"
    docker exec "$POSTGRES_CONTAINER" pg_dump -U postgres -d eucaim-etl-db "${DUMP_ARGS[@]}" > "$BACKUP_FILE"
    echo "Backup written to ${BACKUP_FILE#$ROOT_DIR/}"
  fi
fi

### one transaction for every file: all of it or none of it
{
  echo "BEGIN;"
  for f in "${FILES[@]}"; do
    cat "$DB_DIR/$f"
    printf '\n'
  done
  echo "COMMIT;"
} | "${PSQL[@]}" > /dev/null

echo "✔️ Reloaded: ${GROUPS_WANTED[*]}"
