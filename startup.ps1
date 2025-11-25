# Create directories
$dirs = @(
    "postgres_data",
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
    "output_data\clinical_data",
    "output_data\image_metadata",
	"output_data\mapping_logs",
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

$env:NIFI_USER = "eucaim"
#Write-Host "Nifi user: $env:NIFI_USER"
$env:NIFI_PASSWORD = "eucaim123456789"
#Write-Host "Nifi password: $env:NIFI_PASSWORD"
docker compose down -t 1


# Run Docker Compose
docker compose up -d

#Write-Host "ETL webinterface available at http://localhost:8080"
Write-Host "ETL is running, copy input files into the input_data subfolder"
