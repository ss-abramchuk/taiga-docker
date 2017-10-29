#!/usr/bin/env bash

set -e

echo "[$(date -R)] Restoring taiga media folder"

if [ -n "$TAIGA_BACKUP_STORAGE" ]
then
    source /home/app/scripts/backendenv
    python3 /home/app/taiga/backend/manage.py mediarestore $@
else
    echo "[$(date -R)] Failed: TAIGA_BACKUP_STORAGE undefined"
fi
