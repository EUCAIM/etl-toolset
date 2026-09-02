# Create directories
$dirs = @(
    "nifi_data\nifi_content_repository",
    "nifi_data\nifi_data",
    "nifi_data\nifi_database_repository",
    "nifi_data\nifi_flowfile_repository",
    "nifi_data\nifi_provenance_repository",
    "input_data\clinical_data",
    "input_data\image_metadata",
    "input_data\image_timepoints",
    "staging_data\curated_as_csv\clinical_data",
    "staging_data\input_as_csv\clinical_data",
    "staging_data\input_as_csv\image_metadata",
    "staging_data\input_as_csv\image_timepoints",
    "output_data",
	"output_data\mapping_logs",
    "output_data\etl_process_logs",
    "registry\database",
    "registry\flow-storage",
    "TDC_Output"
)

foreach ($dir in $dirs) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir | Out-Null
    }
}

# Get the local IP address (first non-loopback IPv4)
$localIP = (Get-NetIPAddress -AddressFamily IPv4 `
            | Where-Object { $_.IPAddress -ne "127.0.0.1" -and $_.InterfaceAlias -notlike "*Virtual*" } `
            | Select-Object -First 1 -ExpandProperty IPAddress)

# Set environment variable for current session
$env:LOCAL_IP = $localIP

#Write-Host "Local IP: $env:LOCAL_IP"

#Write-Host "Nifi user: $env:NIFI_USER"
$env:NIFI_USER = "eucaim"

#Write-Host "Nifi password: $env:NIFI_PASSWORD"
$env:NIFI_PASSWORD = "eucaim123456789"

# Node-local configuration, empty in a clean checkout. A value already in the
# environment wins over the file, so a datasetsList committed here by mistake
# cannot silently override an explicit selection.
$datasetsFromEnv = $env:datasetsList
$downloadFromEnv = $env:downloadFlows
if (Test-Path ".\local_env.ps1") {
    . .\local_env.ps1
}
if ($datasetsFromEnv) {
    $env:datasetsList = $datasetsFromEnv
}
if ($downloadFromEnv) {
    $env:downloadFlows = $downloadFromEnv
}

# Datasets whose mappings init.sh pulls from EUCAIM/etl-mappings. Empty on a
# clean deployment: this node downloads no mapping until its operator selects
# the datasets it serves.
if (-not $env:datasetsList) {
    $env:datasetsList = ""
    Write-Host "No dataset selected: set datasetsList to a comma separated list of dataset codes to download their mappings"
} else {
    Write-Host "Datasets to be deployed: $env:datasetsList"
}

# The download overwrites .\flows on every start, so a mapping being adjusted
# locally is lost unless this is turned off. Defaults to the usual behaviour.
if (-not $env:downloadFlows) {
    $env:downloadFlows = "true"
}
if ($env:downloadFlows.ToLower() -in @("false", "no", "0", "off")) {
    Write-Host "Mapping download disabled: the flows already in .\flows will be used as they are"
}

# loop04 writes one CSV per export run, so these folders reach hundreds of files
# in a few weeks and stop being readable. The rows they contain stay in the
# ingestion database, which is what the export reads from, so dropping the old
# files loses nothing. Only the files loop04 generates are matched: etl-errors.log
# and its rotations are logback's business, and anything the operator put there by
# hand is left alone. Set to 0 to keep everything.
if (-not $env:logsRetentionDays) { $env:logsRetentionDays = "30" }
$retention = 0
if ([int]::TryParse($env:logsRetentionDays, [ref]$retention) -and $retention -gt 0) {
    $cutoff = (Get-Date).AddDays(-$retention)
    $patterns = @("output_data\mapping_logs\mapping_results_*_records.csv",
                  "output_data\etl_process_logs\process_logs_*_records.csv")
    $removed = 0
    foreach ($pattern in $patterns) {
        $old = Get-ChildItem -Path $pattern -File -ErrorAction SilentlyContinue |
               Where-Object { $_.LastWriteTime -lt $cutoff }
        $removed += @($old).Count
        $old | Remove-Item -Force -ErrorAction SilentlyContinue
    }
    if ($removed -gt 0) {
        Write-Host "Removed $removed exported log files older than $retention days"
    }
} elseif ($env:logsRetentionDays -ne "0") {
    Write-Host "logsRetentionDays is not a number, skipping the cleanup"
}

# Run Docker Compose
docker compose down -t 1
docker compose up -d

Write-Host "ETL admin web interface available at http://localhost:8080"
Write-Host "ETL is running, copy input files into the input_data subfolder"
