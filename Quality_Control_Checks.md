# EUCAIM ETL – Quality Control Checks

## Summary

The EUCAIM ETL runs quality checks at three points: inside the pipeline on every ingestion, on demand after a dataset is loaded, and as regression tests on synthetic data. The in-pipeline data quality assessment is done by the TDC tool (FORTH). The checks report problems but do not reject data: only structurally broken files stop the pipeline.

| Layer | Check | Runs | Stops the pipeline |
| --- | --- | --- | --- |
| Pipeline | TDC data quality assessment (missing values, data types, outliers, correlated and similar features) | Every ingestion, per clinical entity file | No, reports only |
| Pipeline | CSV structure (empty file, column count per row, others) | Every ingestion | Yes, the file is rejected |
| Pipeline | Failure traceability (files sent to failure or dropped) | Every ingestion | No, it logs the failure |
| Post-load | Ingestion checks (counts, coded fields filled, imaging spread, referential integrity) | On demand | No |
| Post-load | Output checks (same picture on the CDM output schema) | On demand | No |
| Post-load | Ingestion vs output comparison | On demand | No |
| Post-load | Imaging timepoint linkage | On demand | No |
| Post-load | Coded values are valid EUCAIM concept codes | On demand | No |
| Post-load | CDM CSV bundle against the database | On demand | No |
| Development | Regression tests on synthetic data per dataset mapping | Each release / CI | No |

## 1. Checks inside the pipeline

These run automatically on every ingestion of a clinical dataset.

### 1.1 TDC data quality assessment

The clinical data is split into one CSV per CDM entity (patient, condition, episode, procedure, and so on). Each file is sent to the [TDC (Tabular Data Curation) tool](https://github.com/vpz4/TDC) developed by FORTH (detailed documentation there). The ETL calls it in the second pipeline of the clinical data ingestion.

| Check | What it detects |
| --- | --- |
| Missing values per feature | Counts empty values per column. Empty, `?`, `None` and `NaN` all count as missing. Each feature is rated good (none missing), fair (some missing) or bad (at least one third missing). |
| Data type annotation | Infers the type of each feature (categorical, integer, float, text). |
| Type incompatibilities | Flags features whose values do not agree with the inferred type, such as text in a numeric column. |
| Outliers | Flags numeric values that are outliers by the modified z-score (median and median absolute deviation). |
| Highly correlated features | Lists pairs of features with a high Spearman rank correlation. |
| Lexically similar features | Lists pairs of feature names that are close by Jaro distance, a sign of duplicated or misnamed columns. |
| Duplicated feature names | Renames repeated column names so they can be told apart. |

The TDC does not change the values or drop features in the data the ETL loads. The pipeline goes on with the full curated dataset, not with the clean version from which bad features are removed.&#32;

### 1.2 CSV structure check

When the clinical input is converted to CSV, before curation, each file is checked for two things:

- the file is not empty and has a header row
- every row has the same number of columns as the header

A file that fails is rejected. The log says which line failed and suggests the usual cause, such as an unquoted comma. The row content is not logged because it is patient data.

### 1.3 Failure traceability

Every file that a processor sends to failure, retry or unmatched is recorded in the ETL `ProcessLog` table. The record names the pipeline step and the processor where the file stopped. It covers files that would otherwise be dropped without trace. This check is about the process, not the data values, but it makes sure an incomplete load leaves a trace.

## 2. Checks after a dataset is loaded

The node operator runs these read-only checks against the ETL database. The first four run together with one command (`check_data.sh`, or `check_data.ps1` on Windows); the last two run separately. They are bundled so a node can run them without upgrading the ETL. They print aggregate figures only, so their output can be shared without exposing patient identifiers.

| Script | What it checks |
| --- | --- |
| `check_ingestion_data.sql` | Data as loaded by the dataset mapping. Rows per dataset and per entity. How many rows have each EUCAIM coded field filled. Spread of imaging studies and series across modalities. Referential integrity: patients with no dataset, studies with no series, orphan records. Patients that have both clinical and imaging data. |
| `check_output_data.sql` | The same checks on the output schema that the CDM deliverable is built from. |
| `check_ingestion_vs_output.sql` | Datasets present in ingestion but missing from output. Entity counts on both sides. Processed patients with no matching patient in output. |
| `check_imaging_timepoints.sql` | Per dataset, how many imaging studies have a timepoint and are linked to an imaging procedure. For each unlinked study, the first cause that applies. Studies and procedures per timepoint number, to show where the imaging and clinical files stop agreeing. |
| `check_coded_columns.sql` | Values in the coded columns of the output that are not EUCAIM concept codes: free text that never went through the terminology lookup, failed lookups, and codes no longer in the EUCAIM hyperontology. It can be set to fail on any finding, which we use to build reference datasets. |
| `check_cdm_bundle.sh` | The exported CDM CSV files. The export manifest says the bundle is complete. Each CSV header matches its CDM table column by column, in order. Row counts agree between the files, the manifest and the database. Leftover files from earlier runs. |

How to read the result: the patient count must match the clinical source file, and the study and series counts the DICOM metadata. A coded field with 0 filled rows means the mapping is not producing that concept. All referential integrity counts must be 0.

## 3. Regression tests

The dataset mappings are tested by loading synthetic sample data through the full pipeline. The tests check that every pipeline stage produces output, and that specific synthetic patients end up with the expected EUCAIM codes, entity counts and links. They run in continuous integration. They validate the mappings, not the data of the contributing sites.

## 4. Reports and how to get them

| Output | Produced by | Where | Contains patient data |
| --- | --- | --- | --- |
| Evaluation report (`*_evaluation_report.xlsx`) | TDC, per clinical entity | `TDC_Output/` on the node | Feature summaries, which can list value ranges and category values |
| Curated dataset (`*_curated_dataset_backup.xlsx`), problem cells colour-coded | TDC | `TDC_Output/` | Yes |
| Clean dataset (`*_curated_dataset_clean.xlsx`), bad features removed | TDC | `TDC_Output/` | Yes |
| Correlation and lexical similarity reports (`*_similarity_report_*.xlsx`) | TDC | `TDC_Output/` | No, feature pairs only |
| All of the above as JSON (`*_results.json`) | TDC | `TDC_Output/` | Yes |
| Failure log | Pipeline | `ProcessLog` table in the ETL database | No |
| Post-load check output | Check scripts, printed to the console | Saved by the operator, e.g. `check_data.sh > checks.txt` | No, aggregates only |

All reports stay on the node. Reports with patient data must not leave it. To share an example of the reports, we can generate them from synthetic data.

To run the post-load checks, from the ETL root directory with the ETL running:

```bash
scripts/check_data.sh <dataset_id>
```
