## Installation Instructions

1. Download and unzip the file from the [Releases](https://scm.cloud-bahiasoftware.es/rpalpal/Eucaim_ETL/releases) section.
2. Run the startup script:
   - **Linux:** `startup.sh`
   - **Windows:** `startup.ps1`

> **Note:**  
> Running the script for the first time will trigger the download of approximately **6 GB** of data required to build the necessary Docker images. Make sure you have Docker installed and sufficient disk space available.


	
## Installation requirements ##

-  Docker
-  Docker compose

## Dataset requirements ##

- CSV input files **must be comma (,)** separated
- CSV input files **must use dot (.)** as a decimal separator

> **Note:**
> The dataset is expected to have the same header as the template sample file(s) provided to EUCAIM for building and adjusting the mapping.

## Dataset input folder ##

- `input_data\clinical_data`

## Dataset output folders ##

- `output_data\clinical_data`
- `output_data\mapping_logs` 