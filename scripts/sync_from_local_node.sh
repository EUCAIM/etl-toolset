#!/bin/bash
###
### Brings into this branch what the reference node shares with the docker-compose
### distribution, which is developed in Local_Node. Local_Node stays the only source:
### nothing copied here is meant to be edited in this branch. A change goes to
### Local_Node (or to etl-mappings) and is synchronised again.
###
###   Local_Node                      this branch
###   Database/<n>_*.sql          ->  images/postgresql/init-db-scripts/
###   scripts/*.groovy            ->  shared-files/scripts/
###   flows/Clinical_data_*.json  ->  shared-files/flows/
###   flows/Dicom_*.json          ->  shared-files/flows/
###   init.sh                     ->  shared-files/init.sh
###   nifi_conf/logback.xml       ->  shared-files/logback.xml
###   postgresql-*.jar, *.jks     ->  shared-files/
###   TDC/                        ->  images/TDC/
###   etl-mappings/*.json         ->  shared-files/flows/       (one mapping per dataset)
###
### Each destination is replaced whole, so a file removed in the source is removed
### here too. What is specific to this branch (chart/, images/nifi, images/desktop,
### the Dockerfile of postgresql) is never touched. shared-files/SOURCE records the
### commits synchronised.
###
### Usage:
###   scripts/sync_from_local_node.sh                       # origin/Local_Node + origin/main of etl-mappings
###   scripts/sync_from_local_node.sh --local <ref>         # another commit of etl-toolset
###   scripts/sync_from_local_node.sh --local-dir <dir>     # a checkout, uncommitted changes included
###   scripts/sync_from_local_node.sh --mappings-dir <dir>  # the etl-mappings clone (default ../etl-mappings)
###   scripts/sync_from_local_node.sh --mappings-ref <ref>  # its commit (default origin/main)
###

set -e
set -o pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

LOCAL_REF="origin/Local_Node"
LOCAL_DIR=""
MAPPINGS_DIR="$ROOT_DIR/../etl-mappings"
MAPPINGS_REF="origin/main"

while [ $# -gt 0 ]; do
  case "$1" in
    --local)        LOCAL_REF="$2"; shift 2 ;;
    --local-dir)    LOCAL_DIR="$2"; shift 2 ;;
    --mappings-dir) MAPPINGS_DIR="$2"; shift 2 ;;
    --mappings-ref) MAPPINGS_REF="$2"; shift 2 ;;
    -h|--help)      sed -n '2,/^$/p' "${BASH_SOURCE[0]}" | sed 's/^### \{0,1\}//'; exit 0 ;;
    *) echo "❌ unknown argument: $1 (try --help)"; exit 2 ;;
  esac
done

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
SRC="$WORK/local"
MAP="$WORK/mappings"
mkdir -p "$SRC" "$MAP"

### sources, taken from a commit unless a directory is given, so the result does not
### depend on whatever is lying around in a working tree
if [ -n "$LOCAL_DIR" ]; then
  LOCAL_DIR="$(cd "$LOCAL_DIR" && pwd)"
  (cd "$LOCAL_DIR" && git ls-files -z -- Database scripts flows init.sh nifi_conf TDC 'postgresql-*.jar' '*.jks') \
    | (cd "$LOCAL_DIR" && xargs -0 tar -cf -) | tar -xf - -C "$SRC"
  LOCAL_DESC="$LOCAL_DIR @ $(git -C "$LOCAL_DIR" rev-parse --short HEAD) + uncommitted changes"
else
  git -C "$ROOT_DIR" rev-parse --verify -q "$LOCAL_REF^{commit}" > /dev/null \
    || { echo "❌ $LOCAL_REF not found, fetch it first"; exit 1; }
  git -C "$ROOT_DIR" archive "$LOCAL_REF" -- Database scripts flows init.sh nifi_conf TDC \
    $(git -C "$ROOT_DIR" ls-tree --name-only "$LOCAL_REF" | grep -E '^postgresql-.*\.jar$|\.jks$') \
    | tar -xf - -C "$SRC"
  LOCAL_DESC="$LOCAL_REF @ $(git -C "$ROOT_DIR" rev-parse --short "$LOCAL_REF")"
fi

[ -d "$MAPPINGS_DIR/.git" ] || { echo "❌ $MAPPINGS_DIR is not a clone of etl-mappings (use --mappings-dir)"; exit 1; }
git -C "$MAPPINGS_DIR" rev-parse --verify -q "$MAPPINGS_REF^{commit}" > /dev/null \
  || { echo "❌ $MAPPINGS_REF not found in $MAPPINGS_DIR, fetch it first"; exit 1; }
git -C "$MAPPINGS_DIR" archive "$MAPPINGS_REF" | tar -xf - -C "$MAP"
MAPPINGS_DESC="etl-mappings $MAPPINGS_REF @ $(git -C "$MAPPINGS_DIR" rev-parse --short "$MAPPINGS_REF")"

### a mapping that still connects to nifi-postgres would work in docker and fail here
if ! python3 "$SRC/scripts/parametrize_db_connection.py" --check "$SRC"/flows/Clinical_data_*.json "$SRC"/flows/Dicom_*.json "$MAP"/*.json; then
  echo "❌ fix those flows in their source first, nothing was synchronised"
  exit 1
fi

replace_dir() {   # replace_dir <dest> <files...>
  local dest="$ROOT_DIR/$1"; shift
  rm -rf "$dest"
  mkdir -p "$dest"
  [ $# -gt 0 ] && cp -p "$@" "$dest/"
}

shopt -s nullglob

replace_dir images/postgresql/init-db-scripts "$SRC"/Database/[0-9]*.sql
replace_dir shared-files/scripts "$SRC"/scripts/*.groovy
replace_dir shared-files/flows "$SRC"/flows/Clinical_data_*.json "$SRC"/flows/Dicom_*.json "$MAP"/*.json

cp -p "$SRC/init.sh" "$ROOT_DIR/shared-files/init.sh"
cp -p "$SRC/nifi_conf/logback.xml" "$ROOT_DIR/shared-files/logback.xml"
cp -p "$SRC"/postgresql-*.jar "$SRC"/*.jks "$ROOT_DIR/shared-files/"

rm -rf "$ROOT_DIR/images/TDC"
cp -a "$SRC/TDC" "$ROOT_DIR/images/TDC"

cat > "$ROOT_DIR/shared-files/SOURCE" <<EOF
Synchronised by scripts/sync_from_local_node.sh on $(date -u +%Y-%m-%dT%H:%M:%SZ). Do not edit these files here.
etl-toolset  $LOCAL_DESC
$MAPPINGS_DESC
EOF

echo "✅ synchronised from $LOCAL_DESC and $MAPPINGS_DESC"
git -C "$ROOT_DIR" status --short -- images/postgresql/init-db-scripts shared-files images/TDC
