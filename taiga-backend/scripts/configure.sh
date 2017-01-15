#!/usr/bin/env bash

set -e

POSTGRES_DEFAULT_USER=${POSTGRES_DEFAULT_USER:-$POSTGRES_USER}
POSTGRES_DEFAULT_PASS=${POSTGRES_DEFAULT_PASS:-$POSTGRES_PASSWORD}

RABBITMQ_DEFAULT_USER=${RABBITMQ_DEFAULT_USER:-}
RABBITMQ_DEFAULT_PASS=${RABBITMQ_DEFAULT_PASS:-}

export TAIGA_POSTGRES_DB=${TAIGA_POSTGRES_DB:-taiga}
export TAIGA_POSTGRES_USER=${TAIGA_POSTGRES_USER:-taiga}
export TAIGA_POSTGRES_PASSWORD=${TAIGA_POSTGRES_PASSWORD:-insecurepassword}
export TAIGA_EVENTS_ENABLE=${TAIGA_EVENTS_ENABLE:-}
export TAIGA_RABBITMQ_VHOST=${TAIGA_RABBITMQ_VHOST:-}
export TAIGA_RABBITMQ_USER=${TAIGA_RABBITMQ_USER:-}
export TAIGA_RABBITMQ_PASSWORD=${TAIGA_RABBITMQ_PASSWORD:-}
export TAIGA_SECRET_KEY=${TAIGA_SECRET_KEY:-}
export TAIGA_DOMAIN=${TAIGA_DOMAIN:-}
export TAIGA_SSL_ENABLE=${TAIGA_SSL_ENABLE:-}
export TAIGA_EMAIL_USE_TLS=${TAIGA_EMAIL_USE_TLS:-}
export TAIGA_EMAIL_USE_SSL=${TAIGA_EMAIL_USE_SSL:-}
export TAIGA_EMAIL_HOST=${TAIGA_EMAIL_HOST:-}
export TAIGA_EMAIL_PORT=${TAIGA_EMAIL_PORT:-}
export TAIGA_EMAIL_HOST_USER=${TAIGA_EMAIL_HOST_USER:-}
export TAIGA_EMAIL_HOST_PASSWORD=${TAIGA_EMAIL_HOST_PASSWORD:-}
export TAIGA_DEFAULT_FROM_EMAIL=${TAIGA_DEFAULT_FROM_EMAIL:-}
export TAIGA_PUBLIC_REGISTER_ENABLED=${TAIGA_PUBLIC_REGISTER_ENABLED:-}
export TAIGA_DEBUG=${TAIGA_DEBUG:-}
export TAIGA_BACKUP_STORAGE=${TAIGA_BACKUP_STORAGE:-}
export TAIGA_BACKUP_OPTIONS=${TAIGA_BACKUP_OPTIONS:-}
export TAIGA_BACKUP_KEEP=${TAIGA_BACKUP_KEEP:-}

# Configure PostgreSQL DB for Taiga
echo "Waiting for Postgresql to be available..."
wait-for-it pgsql-server:5432 -t 30

unset POPULATE

echo "Check whether taiga user exists."
USEREXIST=$(PGPASSWORD=$POSTGRES_DEFAULT_PASS psql -h pgsql-server -p 5432 -U "$POSTGRES_DEFAULT_USER" -tAc "SELECT rolname FROM pg_roles WHERE rolname='$TAIGA_POSTGRES_USER'")
if [ -z "$USEREXIST" ]
then
    echo "User doesn't exist. Creating new one."
    PGPASSWORD=$POSTGRES_DEFAULT_PASS psql -h pgsql-server -p 5432 -U "$POSTGRES_DEFAULT_USER" -c "CREATE USER $TAIGA_POSTGRES_USER WITH PASSWORD '$TAIGA_POSTGRES_PASSWORD'"
    POPULATE=true
fi

echo "Check whether taiga database exists."
DBEXIST=$(PGPASSWORD=$POSTGRES_DEFAULT_PASS psql -h pgsql-server -p 5432 -U "$POSTGRES_DEFAULT_USER" -tAc "SELECT datname FROM pg_database WHERE datname='$TAIGA_POSTGRES_DB'")
if [ -z "$DBEXIST" ]
then
    echo "Database doesn't exist. Creating new one."
    PGPASSWORD=$POSTGRES_DEFAULT_PASS psql -h pgsql-server -p 5432 -U "$POSTGRES_DEFAULT_USER" -c "CREATE DATABASE $TAIGA_POSTGRES_DB OWNER $TAIGA_POSTGRES_USER"
    POPULATE=true
fi

cd /home/app/taiga/backend

python manage.py migrate --noinput

if [ -n "$POPULATE" ]
then
    echo "Populating a database with initial data."
    python manage.py loaddata initial_user
    python manage.py loaddata initial_project_templates
    python manage.py loaddata initial_role
else
    python manage.py loaddata initial_project_templates --traceback
fi

python manage.py compilemessages
python manage.py collectstatic --noinput

cd /

# Configure RabbitMQ for Taiga
if [ "$TAIGA_EVENTS_ENABLE" = True ]
then
    echo "Waiting for RabbitMQ to be available..."
    wait-for-it rabbitmq-server:5672 -t 30

    RABBIT_ADMIN_INSTALLED=$(command -v rabbitmqadmin || true)
    if [ -z "$RABBIT_ADMIN_INSTALLED" ]
    then
        echo "Util rabbitmqadmin wasn't found. Downloading..."
        wait-for-it rabbitmq-server:15672 -t 30
        curl http://rabbitmq-server:15672/cli/rabbitmqadmin -o /usr/local/bin/rabbitmqadmin
        chmod +x /usr/local/bin/rabbitmqadmin
    fi

    echo "Check whether taiga user exists."
    USEREXIST=$(rabbitmqadmin -f bash -H rabbitmq-server -u $RABBITMQ_DEFAULT_USER -p $RABBITMQ_DEFAULT_PASS list users name | grep -wo $TAIGA_RABBITMQ_USER || true)
    if [ -z "$USEREXIST" ]
    then
        echo "User doesn't exist. Creating new one."
        rabbitmqadmin -H rabbitmq-server -u $RABBITMQ_DEFAULT_USER -p $RABBITMQ_DEFAULT_PASS declare user name=$TAIGA_RABBITMQ_USER password=$TAIGA_RABBITMQ_PASSWORD tags=administrator
    fi

    echo "Check whether taiga vhost exists."
    VHOSTEXIST=$(rabbitmqadmin -f bash -H rabbitmq-server -u $RABBITMQ_DEFAULT_USER -p $RABBITMQ_DEFAULT_PASS list vhosts name | grep -wo $TAIGA_RABBITMQ_VHOST || true)
    if [ -z "$VHOSTEXIST" ]
    then
        echo "Vhost doesn't exist. Creating new one."
        rabbitmqadmin -H rabbitmq-server -u $RABBITMQ_DEFAULT_USER -p $RABBITMQ_DEFAULT_PASS declare vhost name=$TAIGA_RABBITMQ_VHOST
        rabbitmqadmin -H rabbitmq-server -u $RABBITMQ_DEFAULT_USER -p $RABBITMQ_DEFAULT_PASS declare permission vhost=$TAIGA_RABBITMQ_VHOST user=$TAIGA_RABBITMQ_USER configure='.*' write='.*' read='.*'
    fi
fi

chown -R app /home/app/taiga
