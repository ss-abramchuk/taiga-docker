#!/bin/bash -e

POSTGRES_DEFAULT_USER=${POSTGRES_DEFAULT_USER:-$POSTGRES_USER}
POSTGRES_DEFAULT_PASSWORD=${POSTGRES_DEFAULT_PASSWORD:-$POSTGRES_PASSWORD}

RABBITMQ_DEFAULT_USER=${RABBITMQ_DEFAULT_USER:-}
RABBITMQ_DEFAULT_PASS=${RABBITMQ_DEFAULT_PASS:-}

export TAIGA_POSTGRES_DB=${TAIGA_POSTGRES_DB:-taiga}
export TAIGA_POSTGRES_USER=${TAIGA_POSTGRES_USER:-taiga}
export TAIGA_POSTGRES_PASSWORD=${TAIGA_POSTGRES_PASSWORD:-insecurepassword}
export TAIGA_EVENTS_ENABLE=${TAIGA_EVENTS_ENABLE:-False}
export TAIGA_RABBITMQ_VHOST=${TAIGA_RABBITMQ_VHOST:-}
export TAIGA_RABBITMQ_USER=${TAIGA_RABBITMQ_USER:-}
export TAIGA_RABBITMQ_PASSWORD=${TAIGA_RABBITMQ_PASSWORD:-}
export TAIGA_SECRET_KEY=${TAIGA_SECRET_KEY:-insecurekey}
export TAIGA_DOMAIN=${TAIGA_DOMAIN:-localhost}
export TAIGA_SSL_ENABLE=${TAIGA_SSL_ENABLE:-False}
export TAIGA_EMAIL_USE_TLS=${TAIGA_EMAIL_USE_TLS:-False}
export TAIGA_EMAIL_USE_SSL=${TAIGA_EMAIL_USE_SSL:-False}
export TAIGA_EMAIL_HOST=${TAIGA_EMAIL_HOST:-localhost}
export TAIGA_EMAIL_PORT=${TAIGA_EMAIL_PORT:-25}
export TAIGA_EMAIL_HOST_USER=${TAIGA_EMAIL_HOST_USER:-None}
export TAIGA_EMAIL_HOST_PASSWORD=${TAIGA_EMAIL_HOST_PASSWORD:-None}
export TAIGA_DEFAULT_FROM_EMAIL=${TAIGA_DEFAULT_FROM_EMAIL:-no-reply@example.com}
export TAIGA_PUBLIC_REGISTER_ENABLED=${TAIGA_PUBLIC_REGISTER_ENABLED:-False}
export TAIGA_DEBUG=${TAIGA_DEBUG:-False}

# Update configuration
echo "Update configuration files."
envtpl --keep-template -o /home/app/taiga/backend/settings/local.py /home/app/taiga/conf-template/backend.conf.j2

# Configure PostgreSQL DB for Taiga
echo "Waiting for Postgresql to be available..."
wait-for-it pgsql-server:5432 -t 30

POPULATE=false

echo "Check whether taiga user exists."
USEREXIST=$(PGPASSWORD=$POSTGRES_DEFAULT_PASSWORD psql -h pgsql-server -p 5432 -U "$POSTGRES_DEFAULT_USER" -tAc "SELECT rolname FROM pg_roles WHERE rolname='$TAIGA_POSTGRES_USER'")
if [ -z "$USEREXIST" ]
then
    echo "User doesn't exist. Creating new one."
    PGPASSWORD=$POSTGRES_DEFAULT_PASSWORD psql -h pgsql-server -p 5432 -U "$POSTGRES_DEFAULT_USER" -c "CREATE USER $TAIGA_POSTGRES_USER WITH PASSWORD '$TAIGA_POSTGRES_PASSWORD'"
    POPULATE=true
fi

echo "Check whether taiga database exists."
DBEXIST=$(PGPASSWORD=$POSTGRES_DEFAULT_PASSWORD psql -h pgsql-server -p 5432 -U "$POSTGRES_DEFAULT_USER" -tAc "SELECT datname FROM pg_database WHERE datname='$TAIGA_POSTGRES_DB'")
if [ -z "$DBEXIST" ]
then
    echo "Database doesn't exist. Creating new one."
    PGPASSWORD=$POSTGRES_DEFAULT_PASSWORD psql -h pgsql-server -p 5432 -U "$POSTGRES_DEFAULT_USER" -c "CREATE DATABASE $TAIGA_POSTGRES_DB OWNER $TAIGA_POSTGRES_USER"
    POPULATE=true
fi

cd /home/app/taiga/backend

python3 manage.py collectstatic --noinput
python3 manage.py migrate --noinput
python3 manage.py compilemessages

if [ "$POPULATE" = true ]
then
    echo "Populating a database with initial data."
    python3 manage.py loaddata initial_user
    python3 manage.py loaddata initial_project_templates
    python3 manage.py loaddata initial_role
fi

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
    USEREXIST=$(rabbitmqadmin -f bash -H rabbitmq-server -u $RABBITMQ_DEFAULT_USER -p $RABBITMQ_DEFAULT_PASS list users name | grep -o $TAIGA_RABBITMQ_USER)
    if [ -z "$USEREXIST" ]
    then
        echo "User doesn't exist. Creating new one."
        rabbitmqadmin -H rabbitmq-server -u $RABBITMQ_DEFAULT_USER -p $RABBITMQ_DEFAULT_PASS declare user name=$TAIGA_RABBITMQ_USER password=$TAIGA_RABBITMQ_PASSWORD tags=administrator
    fi

    echo "Check whether taiga vhost exists."
    VHOSTEXIST=$(rabbitmqadmin -f bash -H rabbitmq-server -u $RABBITMQ_DEFAULT_USER -p $RABBITMQ_DEFAULT_PASS list vhosts name | grep -o $TAIGA_RABBITMQ_VHOST)
    if [ -z "$VHOSTEXIST" ]
    then
        echo "Vhost doesn't exist. Creating new one."
        rabbitmqadmin -H rabbitmq-server -u $RABBITMQ_DEFAULT_USER -p $RABBITMQ_DEFAULT_PASS declare vhost name=$TAIGA_RABBITMQ_VHOST
        rabbitmqadmin -H rabbitmq-server -u $RABBITMQ_DEFAULT_USER -p $RABBITMQ_DEFAULT_PASS declare permission vhost=$TAIGA_RABBITMQ_VHOST user=$TAIGA_RABBITMQ_USER configure='.*' write='.*' read='.*'
    fi
fi

chown -R app /home/app/taiga
