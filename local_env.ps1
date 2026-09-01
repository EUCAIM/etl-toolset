# Local configuration for this node, loaded by startup.ps1.
#
# Kept empty on purpose: a clean deployment must not download any mapping until
# the operator states which datasets this node serves. Nothing here is needed to
# bring the environment up.
#
# Linux and macOS use local_env.sh instead, bash cannot load this file.
#
# Uncomment and edit to select the datasets. Each code must match the prefix of
# a mapping in https://github.com/EUCAIM/etl-mappings, and is the same code used
# in the "code" column of scripts/config.csv:
#
# $env:datasetsList = "de3702e869557fc5981859b7811e3eab"
#
# Several datasets are separated by commas, with no spaces:
#
# $env:datasetsList = "de3702e869557fc5981859b7811e3eab,c20e289e8a3a4c4fa4579d346d4ba27f"
#
# On every start init.sh pulls the selected mappings from EUCAIM/etl-mappings
# into .\flows, overwriting whatever is there. Set downloadFlows to false to
# skip that and use the files already in .\flows, which is what you want while
# adjusting a mapping locally, or on a node with no access to GitHub. The
# mappings for every dataset in datasetsList must then already be in .\flows.
# Defaults to true.
#
# $env:downloadFlows = "false"
