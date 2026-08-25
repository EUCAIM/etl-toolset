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

$env:datasetsList = "4fcdd34b95f8eed2a3d07291e4c2173e,40dbe9fb-c607-445d-a582-dea531b676b1,73f146b7392d86e14927e0812748fcda,78a35ada399a4300c651a08a8b2479b6,90a34e05855697899fe5e22ad6259c89,1181c8428de05bb98fa8896d281cc0fd,25723aa926bfb0d8e0375bbf3f488dfb,c20e289e8a3a4c4fa4579d346d4ba27f,de3702e869557fc5981859b7811e3eab"

# Run Docker Compose
docker compose down -t 1
docker compose up -d

Write-Host "ETL admin web interface available at http://localhost:8080"
Write-Host "ETL is running, copy input files into the input_data subfolder"
