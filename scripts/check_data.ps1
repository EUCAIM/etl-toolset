# Runs the data-quality SQL checks (ingestion, output, and the
# ingestion-vs-output comparison) against the running nifi-postgres
# container in one shot. The PowerShell counterpart of check_data.sh.
#
# Usage:
#   .\scripts\check_data.ps1                    # every dataset
#   .\scripts\check_data.ps1 <dataset_id>       # scoped to one dataset
#   .\scripts\check_data.ps1 <dataset_id> > checks.txt

param([string]$Dataset)

# left at its default on purpose: psql writes notices to stderr, and under
# "Stop" some PowerShell versions turn that into a terminating error. Every
# call below is checked through $LASTEXITCODE instead
$RootDir = Split-Path -Parent $PSScriptRoot
$ScriptsDir = Join-Path $RootDir "scripts"

# docker compose resolves the container of this project, which is what the
# shell version does too. A compose that cannot answer (an environment variable
# it wants missing, an older docker) still leaves the container reachable by the
# fixed container_name the compose file gives it.
$PostgresContainer = $null
try {
    $PostgresContainer = (& docker compose -f (Join-Path $RootDir "docker-compose.yaml") ps -q nifi-postgres 2>$null |
                          Where-Object { $_ } | Select-Object -First 1)
} catch { }
if (-not $PostgresContainer) {
    $PostgresContainer = (& docker ps --filter "name=^/nifi-postgres$" --format "{{.ID}}" 2>$null |
                          Where-Object { $_ } | Select-Object -First 1)
}
if (-not $PostgresContainer) {
    Write-Host "ERROR: nifi-postgres is not running (docker found nothing)"
    exit 1
}

$PsqlArgs = @("-U", "postgres", "-d", "eucaim-etl-db")
if ($Dataset) {
    # the quotes are part of the value: :dataset must expand to a SQL literal.
    # No shell is involved between here and psql, so they survive as they are
    $PsqlArgs += @("-v", "dataset='$Dataset'")
}

$Failed = 0

foreach ($f in @("check_ingestion_data.sql", "check_output_data.sql", "check_ingestion_vs_output.sql", "check_imaging_timepoints.sql")) {
    $local = Join-Path $ScriptsDir $f
    if (-not (Test-Path $local)) {
        Write-Host "ERROR: $f not found in $ScriptsDir"
        exit 1
    }

    Write-Host ""
    Write-Host "==== $f ===="

    # the file is copied into the container instead of being piped into psql:
    # PowerShell has no "<" redirection, and piping rewrites the encoding on the
    # way. docker cp moves the bytes untouched
    & docker cp $local "${PostgresContainer}:/tmp/$f" | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: could not copy $f into the container"
        $Failed = 1
        continue
    }

    & docker exec $PostgresContainer psql @PsqlArgs -f "/tmp/$f"
    if ($LASTEXITCODE -ne 0) { $Failed = 1 }

    & docker exec $PostgresContainer rm -f "/tmp/$f" | Out-Null
}

Write-Host ""
if ($Failed -ne 0) {
    Write-Host "Some checks did not run, see the errors above"
    exit 1
}
