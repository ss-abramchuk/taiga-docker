#!/bin/bash -e

export TAIGA_RABBITMQ_VHOST=${TAIGA_RABBITMQ_VHOST:-}
export TAIGA_RABBITMQ_USER=${TAIGA_RABBITMQ_USER:-}
export TAIGA_RABBITMQ_PASSWORD=${TAIGA_RABBITMQ_PASSWORD:-}
export TAIGA_SECRET_KEY=${TAIGA_SECRET_KEY:-insecurekey}

# Update configuration
echo "Update configuration files."
envtpl --keep-template -o /home/app/taiga/events/config.json /home/app/taiga/conf-template/events.conf.j2

chown -R app /home/app/taiga
