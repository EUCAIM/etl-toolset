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
