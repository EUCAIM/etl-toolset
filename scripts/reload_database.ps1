# Applies again, over the running nifi-postgres, the Database/*.sql files that hold
# reference data and code, so a node deployed from an earlier commit can pick up new lookup
# values, ontology concepts or procedures without recreating the database. The PowerShell
# counterpart of reload_database.sh, which documents it in full.
#
# Groups: aux (4_init_eucaim_etl_aux), procedures (6, 7, 7a, 7b, 7c), ontology (1, 5_patch,
# 5_update, 5z). Default is "aux procedures". Everything selected goes in ONE transaction.
# Rows added by hand to a Lookup* table or to the concept tables are lost: -Backup dumps the
# schemas about to be replaced.
#
# Usage:
#   .\scripts\reload_database.ps1                       # aux + procedures
#   .\scripts\reload_database.ps1 aux                   # only the lookup tables
#   .\scripts\reload_database.ps1 all -Backup           # the three groups, dump first
#   .\scripts\reload_database.ps1 all -DryRun           # list the files, apply nothing

param(
    [Parameter(ValueFromRemainingArguments = $true)][string[]]$Groups,
    [switch]$Backup,
    [switch]$DryRun
)

$RootDir = Split-Path -Parent $PSScriptRoot
$DbDir = Join-Path $RootDir "Database"

$Wanted = @()
foreach ($g in $Groups) {
    switch ($g) {
        { $_ -in "aux", "procedures", "ontology" } { $Wanted += $g }
        "all" { $Wanted += @("aux", "procedures", "ontology") }
        default { Write-Host "ERROR: unknown group '$g' (aux, procedures, ontology, all)"; exit 2 }
    }
}
if ($Wanted.Count -eq 0) { $Wanted = @("aux", "procedures") }

# the order the first-time initialisation uses (alphabetical), restricted to the groups asked
$Files = @()
if ($Wanted -contains "ontology")   { $Files += "1_init_eucaim_hyperontology_codes.sql" }
if ($Wanted -contains "aux")        { $Files += "4_init_eucaim_etl_aux.sql" }
if ($Wanted -contains "ontology")   { $Files += @("5_init_eucaim_hyperontology_codes_patch.sql", "5_init_eucaim_hyperontology_codes_update.sql", "5z_dedup_eucaim_hyperontology_concept.sql") }
if ($Wanted -contains "procedures") { $Files += @("6_procedure_update_output_db_for_dataset.sql", "7_procedure__log_db.sql", "7a_init_eucaim_cdm_output_export_views.sql", "7b_procedure_export_dataset_to_csv.sql", "7c_procedure_report_dataset.sql") }

foreach ($f in $Files) {
    if (-not (Test-Path (Join-Path $DbDir $f))) { Write-Host "ERROR: $f not found in $DbDir"; exit 1 }
}

Write-Host "Groups: $($Wanted -join ' ')"
$Files | ForEach-Object { Write-Host "  $_" }
if ($DryRun) { Write-Host "(dry run: nothing applied)"; exit 0 }

$PostgresContainer = $null
try {
    $PostgresContainer = (& docker compose -f (Join-Path $RootDir "docker-compose.yaml") ps -q nifi-postgres 2>$null |
                          Where-Object { $_ } | Select-Object -First 1)
} catch { }
if (-not $PostgresContainer) {
    $PostgresContainer = (& docker ps --filter "name=^/nifi-postgres$" --format "{{.ID}}" 2>$null |
                          Where-Object { $_ } | Select-Object -First 1)
}
if (-not $PostgresContainer) { Write-Host "ERROR: nifi-postgres is not running"; exit 1 }

if ($Backup) {
    $schemas = @()
    if ($Wanted -contains "aux")      { $schemas += @("-n", "eucaim_etl_aux") }
    if ($Wanted -contains "ontology") { $schemas += @("-n", "eucaim_hyperontology_codes") }
    if ($schemas.Count -gt 0) {
        $name = "reload_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').sql"
        # dumped inside the container and copied out: redirecting the output of a native command
        # in PowerShell would rewrite its encoding
        & docker exec $PostgresContainer sh -c "pg_dump -U postgres -d eucaim-etl-db $($schemas -join ' ') > /tmp/$name"
        if ($LASTEXITCODE -ne 0) { Write-Host "ERROR: the backup failed, nothing was reloaded"; exit 1 }
        & docker cp "${PostgresContainer}:/tmp/$name" (Join-Path $RootDir $name) | Out-Null
        & docker exec $PostgresContainer rm -f "/tmp/$name" | Out-Null
        Write-Host "Backup written to $name"
    }
}

# the files are copied into the container (docker cp moves the bytes untouched) and applied by
# one psql with several -f and --single-transaction: all of it or none of it
$PsqlArgs = @("-U", "postgres", "-d", "eucaim-etl-db", "-v", "ON_ERROR_STOP=1", "-q", "--single-transaction")
foreach ($f in $Files) {
    & docker cp (Join-Path $DbDir $f) "${PostgresContainer}:/tmp/reload_$f" | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Host "ERROR: could not copy $f into the container"; exit 1 }
    $PsqlArgs += @("-f", "/tmp/reload_$f")
}

& docker exec $PostgresContainer psql @PsqlArgs | Out-Null
$rc = $LASTEXITCODE

foreach ($f in $Files) { & docker exec $PostgresContainer rm -f "/tmp/reload_$f" | Out-Null }

if ($rc -ne 0) { Write-Host "ERROR: the reload failed and was rolled back, see the message above"; exit 1 }
Write-Host "Reloaded: $($Wanted -join ' ')"
