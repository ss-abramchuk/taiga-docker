#!/usr/bin/env bash

echo "Start nullmailer"

if [ ! -p /var/spool/nullmailer/trigger ]
then
    rm -f /var/spool/nullmailer/trigger
    mkfifo /var/spool/nullmailer/trigger
fi

chown mail:root /var/spool/nullmailer/trigger
chmod 0622 /var/spool/nullmailer/trigger

exec /usr/sbin/nullmailer-send
