#!/bin/bash -e

# Create configuration files
j2 /home/app/taiga/conf-template/vhost.conf.j2 > /etc/nginx/sites-enabled/vhost.conf
j2 /home/app/taiga/conf-template/backend.conf.j2 > /home/app/taiga/back-end/settings/local.py
j2 /home/app/taiga/conf-template/events.conf.j2 > /home/app/taiga/events/config.json
j2 /home/app/taiga/conf-template/frontend.conf.j2 > /home/app/taiga/front-end/dist/conf.json

# Configure ssl
if [ "$TAIGA_SSL_ENABLE" = True -a ! -z "${TAIGA_SSL_KEY}" -a ! -z "${TAIGA_SSL_CERT}" ]
then
echo "${TAIGA_SSL_CERT}" > /etc/nginx/certs/$TAIGA_DOMAIN.crt
echo "${TAIGA_SSL_KEY}" > /etc/nginx/certs/$TAIGA_DOMAIN.key
fi

# Configure PostgreSQL DB for Taiga
echo "Waiting for Postgresql to be available..."
while ! nc -z $DBSERVER_PORT_5432_TCP_ADDR $DBSERVER_PORT_5432_TCP_PORT; do
  sleep 1
done

POPULATE=false

echo "Check if taiga user exists"
USEREXIST=$(PGPASSWORD=$DBSERVER_ENV_POSTGRES_PASSWORD psql -h "$DBSERVER_PORT_5432_TCP_ADDR" -p "$DBSERVER_PORT_5432_TCP_PORT" -U "$DBSERVER_ENV_POSTGRES_USER" -tAc "SELECT rolname FROM pg_roles WHERE rolname='$TAIGA_POSTGRES_USER'" | wc -l)
if [ $USEREXIST -eq 0 ]
then
    echo "User doesn't exist. Creating new one."
    PGPASSWORD=$DBSERVER_ENV_POSTGRES_PASSWORD psql -h "$DBSERVER_PORT_5432_TCP_ADDR" -p "$DBSERVER_PORT_5432_TCP_PORT" -U "$DBSERVER_ENV_POSTGRES_USER" -c "CREATE USER $TAIGA_POSTGRES_USER WITH PASSWORD '$TAIGA_POSTGRES_PASSWORD'"
    POPULATE=true
fi

echo "Check if taiga database exists"
DBEXIST=$(PGPASSWORD=$DBSERVER_ENV_POSTGRES_PASSWORD psql -lqt -h "$DBSERVER_PORT_5432_TCP_ADDR" -p "$DBSERVER_PORT_5432_TCP_PORT" -U "$DBSERVER_ENV_POSTGRES_USER" | cut -d \| -f 1 | grep -w "$TAIGA_POSTGRES_DB" | wc -l)
if [ $DBEXIST -eq 0 ]
then
    echo "Database doesn't exist. Creating new one."
    PGPASSWORD=$DBSERVER_ENV_POSTGRES_PASSWORD psql -h "$DBSERVER_PORT_5432_TCP_ADDR" -p "$DBSERVER_PORT_5432_TCP_PORT" -U "$DBSERVER_ENV_POSTGRES_USER" -c "CREATE DATABASE $TAIGA_POSTGRES_DB OWNER $TAIGA_POSTGRES_USER"
    POPULATE=true
fi

cd /home/app/taiga/back-end

python3 manage.py collectstatic --noinput
python3 manage.py migrate --noinput
python3 manage.py compilemessages

if [ "$POPULATE" = true ]
then
    echo "Populating a database with initial data"
    python3 manage.py loaddata initial_user
    python3 manage.py loaddata initial_project_templates
    python3 manage.py loaddata initial_role
fi

cd /

# Configure RabbitMQ for Taiga
if [ "$TAIGA_EVENTS_ENABLE" = True ]
then
    echo "Waiting for RabbitMQ to be available..."
    while ! nc -z $EVENTSERVER_PORT_15672_TCP_ADDR $EVENTSERVER_PORT_15672_TCP_PORT; do
      sleep 1
    done

    RABBITMQ_ADMIN_INSTALLED=$(which rabbitmqadmin | wc -l)
    if [ $RABBITMQ_ADMIN_INSTALLED -eq 0 ]
    then
        echo "Util rabbitmqadmin wasn't found. Downloading..."
        curl http://$EVENTSERVER_PORT_15672_TCP_ADDR:$EVENTSERVER_PORT_15672_TCP_PORT/cli/rabbitmqadmin -o /usr/bin/rabbitmqadmin
        chmod +x /usr/bin/rabbitmqadmin
    fi

    echo "Check if taiga user exists"
    USEREXIST=$(rabbitmqadmin -H $EVENTSERVER_PORT_5672_TCP_ADDR -u $EVENTSERVER_ENV_RABBITMQ_DEFAULT_USER -p $EVENTSERVER_ENV_RABBITMQ_DEFAULT_PASS list users | grep $TAIGA_RABBITMQ_USER | wc -l)
    if [ $USEREXIST -eq 0 ]
    then
        echo "User doesn't exist. Creating new one."
        rabbitmqadmin -H $EVENTSERVER_PORT_5672_TCP_ADDR -u $EVENTSERVER_ENV_RABBITMQ_DEFAULT_USER -p $EVENTSERVER_ENV_RABBITMQ_DEFAULT_PASS declare user name=$TAIGA_RABBITMQ_USER password=$TAIGA_RABBITMQ_PASSWORD tags=administrator
    fi

    echo "Check if taiga vhost exists"
    VHOSTEXIST=$(rabbitmqadmin -H $EVENTSERVER_PORT_5672_TCP_ADDR -u $EVENTSERVER_ENV_RABBITMQ_DEFAULT_USER -p $EVENTSERVER_ENV_RABBITMQ_DEFAULT_PASS list vhosts | grep $TAIGA_RABBITMQ_VHOST | wc -l)
    if [ $VHOSTEXIST -eq 0 ]
    then
        echo "Vhost doesn't exist. Creating new one."
        rabbitmqadmin -H $EVENTSERVER_PORT_5672_TCP_ADDR -u $EVENTSERVER_ENV_RABBITMQ_DEFAULT_USER -p $EVENTSERVER_ENV_RABBITMQ_DEFAULT_PASS declare vhost name=$TAIGA_RABBITMQ_VHOST
        rabbitmqadmin -H $EVENTSERVER_PORT_5672_TCP_ADDR -u $EVENTSERVER_ENV_RABBITMQ_DEFAULT_USER -p $EVENTSERVER_ENV_RABBITMQ_DEFAULT_PASS declare permission vhost=$TAIGA_RABBITMQ_VHOST user=$TAIGA_RABBITMQ_USER configure='.*' write='.*' read='.*'
    fi
fi

chown -R app /home/app/taiga
