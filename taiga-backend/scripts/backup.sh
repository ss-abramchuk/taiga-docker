#!/usr/bin/env bash

set -e

if [ -n "$TAIGA_BACKUP_STORAGE" ]
then
    BACKUP_LOG_FILE=/var/log/backup.log
    echo "[$(date -R)] Backing up taiga media folder" >> $BACKUP_LOG_FILE 2>&1
    python /home/app/taiga/backend/manage.py mediabackup --compress --clean >> $BACKUP_LOG_FILE 2>&1
    echo "[$(date -R)] Backing up taiga database" >> $BACKUP_LOG_FILE 2>&1
    python /home/app/taiga/backend/manage.py dbbackup --compress --clean >> $BACKUP_LOG_FILE 2>&1
fi
