#!/bin/bash
set -e

echo "Start nginx"

if [[ ! -e /var/log/nginx/error.log ]]; then
	(sleep 1 && sv restart /etc/service/nginx-log-forwarder)
fi

exec nginx -g "daemon off;"
