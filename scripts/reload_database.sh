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
###   schema       2, 3, 3z + Database/upgrade/   brings the ingestion and output schemas up
###                                               to this version (see below). Implies
###                                               `procedures`, which must match them.
###
### schema: a database created by an earlier version keeps the ingestion and output tables
### of that version, and the procedures of this one then fail on them ("table ... not
### found", "column ... does not exist"). This group builds the schemas this version expects
### from 2, 3 and 3z and compares them with the live ones:
###   * ingestion is reconciled in place, keeping its data: missing tables and columns are
###     added, types widened, NOT NULL relaxed. Columns no longer used are kept.
###   * output is only a projection of ingestion. If its structure differs it is dropped and
###     created again, and every dataset it held is transformed and exported again, each one
###     in its own transaction AFTER the upgrade has committed (upgrade/3_...). One that fails
###     stays queued in public.schema_upgrade_pending and is retried the next time.
### When the schemas already match nothing is changed. Data ingested by an earlier version
### has the columns new to this one empty: to fill them, drop its source files again into
### input_data. The flows UPSERT, so nothing is duplicated. The init flag (8) is never touched.
###
### The default is `aux procedures schema`. Every selected group is applied in ONE
### transaction, so an error leaves the database as it was.
###
### Any row someone added by hand to a Lookup* table, or any change to the concept tables
### made outside these files, is lost: put it in the SQL files first. --backup writes a dump
### of the schemas about to be replaced (with `schema`, also the ingestion and output data).
###
### NiFi needs no restart for SQL changes: the database lookup services do not cache. A
### change to a Groovy script or to a flow does need the flows to be loaded again.
###
### Usage:
###   scripts/reload_database.sh                      # aux + procedures + schema
###   scripts/reload_database.sh aux                  # only the lookup tables
###   scripts/reload_database.sh ontology             # only the concept tables
###   scripts/reload_database.sh schema               # only the schemas (+ procedures)
###   scripts/reload_database.sh all                  # every group
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
    aux|procedures|ontology|schema) GROUPS_WANTED+=("$arg") ;;
    all)       GROUPS_WANTED+=(aux procedures ontology schema) ;;
    -h|--help) sed -n '2,/^$/p' "${BASH_SOURCE[0]}" | sed 's/^### \{0,1\}//'; exit 0 ;;
    *) echo "❌ unknown argument: $arg (try --help)"; exit 2 ;;
  esac
done
[ ${#GROUPS_WANTED[@]} -eq 0 ] && GROUPS_WANTED=(aux procedures schema)

has_group() { local g; for g in "${GROUPS_WANTED[@]}"; do [ "$g" = "$1" ] && return 0; done; return 1; }

### the procedures of this version are written against its schemas, and the other way round
if has_group schema && ! has_group procedures; then GROUPS_WANTED+=(procedures); fi

### files in the order initdb.d would run them (alphabetical), restricted to the groups asked
FILES=()
has_group ontology   && FILES+=(1_init_eucaim_hyperontology_codes.sql)
has_group aux        && FILES+=(4_init_eucaim_etl_aux.sql)
has_group ontology   && FILES+=(5_init_eucaim_hyperontology_codes_patch.sql 5_init_eucaim_hyperontology_codes_update.sql 5z_dedup_eucaim_hyperontology_concept.sql)
### 3z is optional (whoever does not want it deletes the file), so it goes only when present
if has_group schema; then
  FILES+=(upgrade/1_schema_set_aside.sql 2_init_eucaim_cdm_ingestion.sql 3_init_eucaim_cdm_output.sql)
  [ -f "$DB_DIR/3z_relax_segmentation_series.sql" ] && FILES+=(3z_relax_segmentation_series.sql)
  FILES+=(upgrade/2_schema_reconcile.sql)
fi
has_group procedures && FILES+=(6_procedure_update_output_db_for_dataset.sql 7_procedure__log_db.sql 7a_init_eucaim_cdm_output_export_views.sql 7b_procedure_export_dataset_to_csv.sql 7c_procedure_report_dataset.sql)

### applied after the transaction: each of these manages its own
AFTER_FILES=()
has_group schema && AFTER_FILES+=(upgrade/3_schema_regenerate_output.sql)

for f in "${FILES[@]}" "${AFTER_FILES[@]}"; do
  [ -f "$DB_DIR/$f" ] || { echo "❌ $DB_DIR/$f not found"; exit 1; }
done

echo "Groups: ${GROUPS_WANTED[*]}"
printf '  %s\n' "${FILES[@]}"
if [ ${#AFTER_FILES[@]} -gt 0 ]; then printf '  %s (after the commit)\n' "${AFTER_FILES[@]}"; fi
if [ "$DRY_RUN" -eq 1 ]; then echo "(dry run: nothing applied)"; exit 0; fi

### POSTGRES_CONTAINER in the environment picks another container (a copy to try it on)
[ -z "$POSTGRES_CONTAINER" ] && POSTGRES_CONTAINER=$(docker compose -f "$ROOT_DIR/docker-compose.yaml" ps -q nifi-postgres 2>/dev/null || true)
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
  has_group schema   && DUMP_ARGS+=(-n eucaim_cdm_ingestion -n eucaim_cdm_output)
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

for f in "${AFTER_FILES[@]}"; do
  "${PSQL[@]}" < "$DB_DIR/$f" > /dev/null
done
if has_group schema; then
  PENDING=$("${PSQL[@]}" -tA -c "SELECT count(*) FROM public.schema_upgrade_pending")
  if [ "$PENDING" -gt 0 ]; then
    echo "⚠️ $PENDING dataset(s) could not be transformed again (see the warnings above). They stay"
    echo "   queued in public.schema_upgrade_pending and are retried the next time this runs."
    exit 1
  fi
fi
