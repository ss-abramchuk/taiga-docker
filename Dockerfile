FROM phusion/passenger-customizable:0.9.18

MAINTAINER Sergio Abramchuk <ss.abramchuk@gmail.com>

ENV HOME=/root \
    DEBIAN_FRONTEND=noninteractive \
    TAIGA_VERSION=2.0.0 \
    TAIGA_POSTGRES_DB=taiga \
    TAIGA_POSTGRES_USER=taiga \
    TAIGA_POSTGRES_PASSWORD=password \
    TAIGA_EVENTS_ENABLE=False \
    TAIGA_RABBITMQ_VHOST=taiga \
    TAIGA_RABBITMQ_USER=taiga \
    TAIGA_RABBITMQ_PASSWORD=password \
    TAIGA_SECRET_KEY=insecure \
    TAIGA_DOMAIN=localhost \
    TAIGA_SSL_ENABLE=False \
    TAIGA_SSL_KEY= \
    TAIGA_SSL_CERT= \
    TAIGA_EMAIL_USE_TLS=False \
    TAIGA_EMAIL_USE_SSL=False \
    TAIGA_EMAIL_HOST=localhost \
    TAIGA_EMAIL_PORT=25 \
    TAIGA_EMAIL_HOST_USER=None \
    TAIGA_EMAIL_HOST_PASSWORD=None \
    TAIGA_DEFAULT_FROM_EMAIL=no-reply@example.com \
    TAIGA_PUBLIC_REGISTER_ENABLED=False \
    TAIGA_DEBUG=False

# Installing dependencies
RUN apt-get update && apt-get install -y \
    build-essential binutils-doc autoconf flex bison libjpeg-dev libxml2-dev libpq-dev \
    libxslt-dev libfreetype6-dev zlib1g-dev libzmq3-dev libgdbm-dev libncurses5-dev \
    automake libtool libffi-dev tmux gettext netcat postgresql-client \
    python3 python python3-pip python-pip python3-dev python-dev nodejs && \
    pip install j2cli && npm install --unsafe-perm -g coffee-script

# Installing Taiga back-end
RUN mkdir -p /home/app/taiga && \
    git clone https://github.com/taigaio/taiga-back.git /home/app/taiga/back-end && \
    mkdir -p /home/app/taiga/media /home/app/taiga/static && \
    cd /home/app/taiga/back-end && git checkout $TAIGA_VERSION && \
    pip3 install -r requirements.txt

# Intstalling Taiga events
RUN git clone https://github.com/taigaio/taiga-events.git /home/app/taiga/events && \
    cd /home/app/taiga/events && \
    npm install && coffee -c .

# Installing Taiga front-end
RUN git clone https://github.com/taigaio/taiga-front-dist.git /home/app/taiga/front-end && \
    cd /home/app/taiga/front-end && git checkout $TAIGA_VERSION

# Cleaning up APT
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Configuration
RUN mkdir -p /home/app/taiga/conf-template
COPY ./conf/vhost.conf.j2 /home/app/taiga/conf-template/vhost.conf.j2
COPY ./conf/backend.conf.j2 /home/app/taiga/conf-template/backend.conf.j2
COPY ./conf/events.conf.j2 /home/app/taiga/conf-template/events.conf.j2
COPY ./conf/frontend.conf.j2 /home/app/taiga/conf-template/frontend.conf.j2
COPY ./conf/passenger_wsgi.py /home/app/taiga/back-end/passenger_wsgi.py

# Enabling nginx
RUN rm -f /etc/service/nginx/down && rm /etc/nginx/sites-enabled/default && \
    mkdir -p /etc/nginx/certs

# Copy starting script
COPY ./script/start.sh /etc/my_init.d/start.sh
COPY ./script/wait-for-it.sh /usr/local/bin/wait-for-it
RUN chmod +x /etc/my_init.d/start.sh /usr/local/bin/wait-for-it

VOLUME /home/app/taiga/media

EXPOSE 80 443

CMD ["/sbin/my_init"]
