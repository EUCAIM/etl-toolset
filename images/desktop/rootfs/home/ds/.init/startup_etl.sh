#!/usr/bin/env bash

# Install DBeaver SQL client drivers
if [ -f $HOME/persistent-shared-folder/apps/dbeaver-sql-client/copy-drivers ]; then
    $HOME/persistent-shared-folder/apps/dbeaver-sql-client/copy-drivers
fi

# Run the init script of the base image
source /home/ds/.init/startup.sh
