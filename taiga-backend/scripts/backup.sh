if [ "$TAIGA_BACKUP_SYSTEM" != None ]
then
    echo "Performing backup"
    python /home/app/taiga/backend/manage.py dbbackup --compress
    python /home/app/taiga/backend/manage.py mediabackup --compress
fi
