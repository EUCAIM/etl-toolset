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

## Basic usage ##

The ETL service runs continuously in the background. In the current version, the execution of the pipeline is triggered by placing the dataset files into the **input_data** directory.

The results are generated as a set of CSV files in the corresponding **output_data** directories.

## Dataset requirements ##

- CSV input files **must be comma (,)** separated
- CSV input files **must use dot (.)** as a decimal separator

> **Note:**
> The dataset must have exactly the same header as the template sample file(s) provided to EUCAIM team for building and adjusting the mapping.

## Dataset input folder ##

The dataset file with clinical data must be placed in:
- `input_data\clinical_data`


## Dataset output folders ##

The generated output files, containing the dataset converted into the EUCAIM CDM, are written here:
- `output_data\clinical_data`

Additional output to support the review of the mapping process is written here:
- `output_data\mapping_logs` 



## FAQ (frequently Asked Questions)

### 1. After the input file is copied into `input_data\clinical_data`, nothing happens and the file remains there, seemingly not being processed

If this happens, most likely the setup script **init.sh** is not being properly executed.  
In some instances, due to permission issues, this file cannot run inside the NiFi Docker container.  

To check if this is the case, try:

```bash
docker logs nifi | grep init
sh: 1: /opt/nifi/init.sh: Permission denied

If you see the "Permission denied" message, the solution is to ensure that the file has valid read and execution permissions for the user running the startup script of the ETL.