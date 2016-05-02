#!/bin/bash
set -e

if [[ -e /var/log/nginx/error.log ]]; then
	echo "Start log forwarder"
	exec tail -F /var/log/nginx/error.log
else
	echo "Log forwarder is waiting for nginx"
	exec sleep 10
fi
