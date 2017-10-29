#!/usr/bin/env bash

set -e

echo "[$(date -R)] Restoring taiga database"

if [ -n "$TAIGA_BACKUP_STORAGE" ]
then
    source /home/app/scripts/backendenv
    python3 /home/app/taiga/backend/manage.py dbrestore $@
else
    echo "[$(date -R)] Failed: TAIGA_BACKUP_STORAGE undefined"
fi
