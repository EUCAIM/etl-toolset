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

- Please **include as prefix for ALL the files, the Dataset ID**. Example **4fcdd34b95f8eed2a3d07291e4c2173e_bcancerA_sample.csv**. This Dataset ID can be found in the [EUCAIM catalogue](https://catalogue.eucaim.cancerimage.eu)
- CSV input files **must be comma (,)** separated
- CSV input files **must use dot (.)** as a decimal separator

> **Note:**
> The dataset must have exactly the same header as the template sample file(s) provided to EUCAIM team for building and adjusting the mapping.

## Dataset input folder ##

The dataset file with clinical data must be placed in:
- `input_data\clinical_data`

The csv file with the extraction of DICOM tags must be placed in:
- `input_data\image_metadata`

The csv file declaring the imaging timepoints must be placed in:
- `input_data\image_timepoints`

Please push first at least once, the files for clinical data and DICOM metadata, before submitting the file with the imaging timepoints.


## Dataset output folders ##

The generated output files, containing the dataset converted into the EUCAIM CDM, are written here:
- `output_data\clinical_data`

The generated output files, containing the DICOM metadata converted into the EUCAIM CDM, are written here:
- `output_data\image_metadata`

Additional output to support the review of the mapping process is written here:
- `output_data\mapping_logs` 

## License ##

Except as otherwise noted this software is licensed under the
[Apache License, Version 2.0](https://www.apache.org/licenses/LICENSE-2.0.html)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

  https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

---


## FAQ (frequently Asked Questions)

### 1. After the input file is copied into `input_data\clinical_data`, nothing happens and the file remains there, seemingly not being processed

If this happens, most likely the setup script **init.sh** is not being properly executed.  
In some instances, due to permission issues, this file cannot run inside the NiFi Docker container.  

To check if this is the case, try:

```bash
docker logs nifi | grep init
sh: 1: /opt/nifi/init.sh: Permission denied
```

If you see the "Permission denied" message, the solution is to ensure that the file has valid read and execution permissions for the user running the startup script of the ETL.


### 2. Ingesting the imaging timepoints does not seem to work, and/or is generating errors

Please check the csv file containing the imaging timepoints includes the expected header, with at least the columns **Timepoint** (also "ImagingTimepoint" is valid as column name), **StudyInstanceUID** and **PatientID** (column names no case sensitive).


### 3. The initilization of the nifi-postgres container (the internal ETL database) fails, when it was previously working

Unfortunatly, updating from any release prior to 0.3.X to these or later releases, renders the database storage not compatible. If it s absolutely necessary to preserve previously ingested data, change the version in the docker-compose or contact with us for help. If you can afford to re-ingest the dataset files, please run only the first time after upgrading the ETL:

```bash
docker compose down -v
```

Afterwards execute the launch script as normal, and ingest the files following the same instructions.
