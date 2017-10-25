#!/usr/bin/env bash

set -e

if [ -n "$TAIGA_BACKUP_STORAGE" ]
then
    echo "[$(date -R)] Backing up taiga media folder"
    python3 /home/app/taiga/backend/manage.py mediabackup -z -c
    echo "[$(date -R)] Backing up taiga database"
    python3 /home/app/taiga/backend/manage.py dbbackup -c
fi
