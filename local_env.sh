#!/bin/bash
### Local configuration for this node, loaded by startup.sh.
###
### Kept empty on purpose: a clean deployment must not download any mapping
### until the operator states which datasets this node serves. Nothing here is
### needed to bring the environment up.
###
### Windows uses local_env.ps1 instead, PowerShell cannot load this file.
###
### Uncomment and edit to select the datasets. Each code must match the prefix
### of a mapping in https://github.com/EUCAIM/etl-mappings, and is the same code
### used in the "code" column of scripts/config.csv:
###
### datasetsList="40dbe9fb-c607-445d-a582-dea531b676b1"
###
### Several datasets are separated by commas, with no spaces:
###
### datasetsList="40dbe9fb-c607-445d-a582-dea531b676b1,4fcdd34b95f8eed2a3d07291e4c2173e,1181c8428de05bb98fa8896d281cc0fd,90a34e05855697899fe5e22ad6259c89,73f146b7392d86e14927e0812748fcda,78a35ada399a4300c651a08a8b2479b6,c20e289e8a3a4c4fa4579d346d4ba27f,25723aa926bfb0d8e0375bbf3f488dfb,de3702e869557fc5981859b7811e3eab"

###
### On every start init.sh pulls the selected mappings from EUCAIM/etl-mappings
### into ./flows, overwriting whatever is there. Set downloadFlows to false to
### skip that and use the files already in ./flows, which is what you want while
### adjusting a mapping locally, or on a node with no access to GitHub. The
### mappings for every dataset in datasetsList must then already be in ./flows.
### Defaults to true.
###
downloadFlows="false"
###
### Every export run of the last pipeline leaves one CSV in output_data, so those
### folders reach hundreds of files in a few weeks. On each launch the startup
### script deletes the ones older than this many days. The rows stay in the
### ingestion database the export reads from, so nothing is lost. Set it to 0 to
### delete nothing. Defaults to 30.
###
### logsRetentionDays="30"
