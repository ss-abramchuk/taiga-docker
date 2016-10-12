#!/usr/bin/env bash

set -e

if [ "$TAIGA_BACKUP_SYSTEM" != None ]
then
    BACKUP_LOG_FILE=/var/log/backup.log
    echo "Backup taiga media folder" >> $BACKUP_LOG_FILE 2>&1
    python /home/app/taiga/backend/manage.py mediabackup --compress --clean >> $BACKUP_LOG_FILE 2>&1
    echo "Backup taiga database" >> $BACKUP_LOG_FILE 2>&1
    python /home/app/taiga/backend/manage.py dbbackup --compress --clean >> $BACKUP_LOG_FILE 2>&1
fi
