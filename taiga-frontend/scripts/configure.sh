#!/bin/bash -e

export TAIGA_DOMAIN=${TAIGA_DOMAIN:-localhost}
export TAIGA_SSL_ENABLE=${TAIGA_SSL_ENABLE:-False}
export TAIGA_SSL_KEY=${TAIGA_SSL_KEY:-}
export TAIGA_SSL_CERT=${TAIGA_SSL_CERT:-}
export TAIGA_EVENTS_ENABLE=${TAIGA_EVENTS_ENABLE:-False}
export TAIGA_PUBLIC_REGISTER_ENABLED=${TAIGA_PUBLIC_REGISTER_ENABLED:-False}
export TAIGA_DEBUG=${TAIGA_DEBUG:-False}

# Update configuration files
echo "Update configuration files."
envtpl --keep-template -o /etc/nginx/sites-enabled/vhost.conf /home/app/taiga/conf-template/vhost.conf.j2
envtpl --keep-template -o /home/app/taiga/frontend/dist/conf.json /home/app/taiga/conf-template/frontend.conf.j2

# Configure SSL
if [ "$TAIGA_SSL_ENABLE" = True -a ! -z "$TAIGA_SSL_KEY" -a ! -z "$TAIGA_SSL_CERT" ]
then
    echo "Configure SSL."
    echo "$TAIGA_SSL_CERT" > /etc/nginx/certs/$TAIGA_DOMAIN.crt
    echo "$TAIGA_SSL_KEY" > /etc/nginx/certs/$TAIGA_DOMAIN.key
fi
