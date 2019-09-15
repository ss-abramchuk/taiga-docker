FROM phusion/passenger-customizable:1.0.7

MAINTAINER Sergio Abramchuk <ss.abramchuk@gmail.com>

ENV HOME=/root \
    DEBIAN_FRONTEND=noninteractive \
    APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=True \
    TAIGA_VERSION=4.2.12 \
    TAIGA_ROOT_DIR=/home/app/taiga \
    TAIGA_BACKEND_DIR=backend \
    TAIGA_STATIC_DIR=static \
    TAIGA_MEDIA_DIR=media

# Replace shell with bash so we can source files
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# Add postgresql repo
RUN curl -s https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN add-apt-repository "deb http://apt.postgresql.org/pub/repos/apt/ bionic-pgdg main"

# Install dependencies
RUN apt-get update && /pd_build/utilities.sh && /pd_build/python.sh && apt-get install -y \
    libjpeg-dev libxml2-dev libxslt-dev libffi-dev libfreetype6-dev zlib1g-dev libzmq3-dev \
    libgdbm-dev libncurses5-dev libpq-dev tmux flex bison gettext postgresql-client-9.6 python3-dev && \
    curl https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py && python3 /tmp/get-pip.py

# Install Taiga backend
RUN mkdir -p $TAIGA_ROOT_DIR && \
    git clone https://github.com/taigaio/taiga-back.git $TAIGA_ROOT_DIR/$TAIGA_BACKEND_DIR && \
    mkdir -p $TAIGA_ROOT_DIR/$TAIGA_MEDIA_DIR $TAIGA_ROOT_DIR/$TAIGA_STATIC_DIR && \
    cd $TAIGA_ROOT_DIR/$TAIGA_BACKEND_DIR && git checkout $TAIGA_VERSION

COPY ./conf/additional-requirements.txt $TAIGA_ROOT_DIR/$TAIGA_BACKEND_DIR/additional-requirements.txt
RUN cd $TAIGA_ROOT_DIR/$TAIGA_BACKEND_DIR && cat additional-requirements.txt >> requirements.txt && \
    pip3 install -r requirements.txt

# Clean APT
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Configuration
RUN mkdir -p /etc/service/taiga-backend /home/app/scripts && sed -i '/SHELL/i MAILTO=""' /etc/crontab
COPY ./services/taiga-backend.sh /etc/service/taiga-backend/run
COPY ./conf/backend.py $TAIGA_ROOT_DIR/$TAIGA_BACKEND_DIR/settings/local.py
COPY ./conf/passenger_wsgi.py $TAIGA_ROOT_DIR/$TAIGA_BACKEND_DIR/passenger_wsgi.py
COPY ./conf/Passengerfile.json $TAIGA_ROOT_DIR/$TAIGA_BACKEND_DIR/Passengerfile.json
COPY ./scripts/configure.sh /etc/my_init.d/configure.sh
COPY ./scripts/wait-for-it.sh /usr/local/bin/wait-for-it
COPY ./scripts/backendenv.sh /home/app/scripts/backendenv
COPY ./scripts/dbbackup.sh /home/app/scripts/dbbackup
COPY ./scripts/dbrestore.sh /home/app/scripts/dbrestore
COPY ./scripts/mediabackup.sh /home/app/scripts/mediabackup
COPY ./scripts/mediarestore.sh /home/app/scripts/mediarestore
RUN chmod +x /etc/my_init.d/configure.sh /usr/local/bin/wait-for-it \
    /etc/service/taiga-backend/run /home/app/scripts/backendenv \
    /home/app/scripts/dbbackup /home/app/scripts/dbrestore \
    /home/app/scripts/mediabackup /home/app/scripts/mediarestore && \
    ln -s /home/app/scripts/dbbackup /usr/local/bin/dbbackup && \
    ln -s /home/app/scripts/dbrestore /usr/local/bin/dbrestore && \
    ln -s /home/app/scripts/mediabackup /usr/local/bin/mediabackup && \
    ln -s /home/app/scripts/mediarestore /usr/local/bin/mediarestore

# Workaround for missing group name specified in the logrotate configuration
RUN sed -i '/su root syslog/s/syslog/adm/' /etc/logrotate.conf

VOLUME $TAIGA_ROOT_DIR/$TAIGA_STATIC_DIR $TAIGA_ROOT_DIR/$TAIGA_MEDIA_DIR

EXPOSE 8000

CMD ["/sbin/my_init"]
