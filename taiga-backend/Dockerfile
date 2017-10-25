FROM phusion/passenger-customizable:0.9.23

MAINTAINER Sergio Abramchuk <ss.abramchuk@gmail.com>

ENV HOME=/root \
    DEBIAN_FRONTEND=noninteractive \
    TAIGA_VERSION=3.1.0 \
    TAIGA_ROOT_DIR=/home/app/taiga \
    TAIGA_BACKEND_DIR=backend \
    TAIGA_STATIC_DIR=static \
    TAIGA_MEDIA_DIR=media

# Add postgresql repo
RUN add-apt-repository "deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main" && \
    curl -s https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -

# Install dependencies
RUN apt-get update && /pd_build/utilities.sh && /pd_build/python.sh && apt-get install -y \
    libjpeg-dev libxml2-dev libxslt-dev libffi-dev libfreetype6-dev zlib1g-dev libzmq3-dev \
    libgdbm-dev libncurses5-dev libpq-dev tmux flex bison gettext postgresql-client-9.6 \
    python3-pip python3-dev && ln -s $(command -v python3) /usr/local/bin/python &&\
    ln -s $(command -v pip3) /usr/local/bin/pip

# Install Taiga backend
RUN mkdir -p $TAIGA_ROOT_DIR && \
    git clone https://github.com/taigaio/taiga-back.git $TAIGA_ROOT_DIR/$TAIGA_BACKEND_DIR && \
    mkdir -p $TAIGA_ROOT_DIR/$TAIGA_MEDIA_DIR $TAIGA_ROOT_DIR/$TAIGA_STATIC_DIR && \
    cd $TAIGA_ROOT_DIR/$TAIGA_BACKEND_DIR && git checkout $TAIGA_VERSION && \
    pip install -r requirements.txt

# Install backup dependencies
COPY ./conf/additional-requirements.txt $TAIGA_ROOT_DIR/$TAIGA_BACKEND_DIR/additional-requirements.txt
RUN cd $TAIGA_ROOT_DIR/$TAIGA_BACKEND_DIR && pip install -r additional-requirements.txt

# Clean APT
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Configuration
RUN mkdir -p /etc/service/taiga-backend && sed -i '/SHELL/i MAILTO=""' /etc/crontab
COPY ./services/taiga-backend.sh /etc/service/taiga-backend/run
COPY ./conf/backend.py $TAIGA_ROOT_DIR/$TAIGA_BACKEND_DIR/settings/local.py
COPY ./conf/passenger_wsgi.py $TAIGA_ROOT_DIR/$TAIGA_BACKEND_DIR/passenger_wsgi.py
COPY ./conf/Passengerfile.json $TAIGA_ROOT_DIR/$TAIGA_BACKEND_DIR/Passengerfile.json
COPY ./scripts/configure.sh /etc/my_init.d/configure.sh
COPY ./scripts/wait-for-it.sh /usr/local/bin/wait-for-it
COPY ./scripts/backup.sh /home/app/backup
RUN chmod +x /etc/my_init.d/configure.sh /usr/local/bin/wait-for-it \
    /etc/service/taiga-backend/run /home/app/backup

# Workaround for missing group name specified in the logrotate configuration
RUN sed -i '/su root syslog/s/syslog/adm/' /etc/logrotate.conf

VOLUME $TAIGA_ROOT_DIR/$TAIGA_STATIC_DIR $TAIGA_ROOT_DIR/$TAIGA_MEDIA_DIR

EXPOSE 8000

CMD ["/sbin/my_init"]
