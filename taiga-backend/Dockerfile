FROM phusion/passenger-customizable:0.9.25

MAINTAINER Sergio Abramchuk <ss.abramchuk@gmail.com>

ENV HOME=/root \
    DEBIAN_FRONTEND=noninteractive \
    TAIGA_VERSION=3.1.0

# Install dependencies
RUN apt-get update && /pd_build/utilities.sh && /pd_build/python.sh && apt-get install -y \
    libjpeg-dev libxml2-dev libxslt-dev libffi-dev libfreetype6-dev zlib1g-dev libzmq3-dev \
    libgdbm-dev libncurses5-dev libpq-dev tmux flex bison gettext postgresql-client \
    python3-pip python3-dev && ln -s $(command -v python3) /usr/local/bin/python &&\
    ln -s $(command -v pip3) /usr/local/bin/pip

# Install Taiga backend
RUN mkdir -p /home/app/taiga && \
    git clone https://github.com/taigaio/taiga-back.git /home/app/taiga/backend && \
    mkdir -p /home/app/taiga/media /home/app/taiga/static && \
    cd /home/app/taiga/backend && git checkout $TAIGA_VERSION && \
    pip install -r requirements.txt && pip install django-dbbackup paramiko boto dropbox \
    django-storages

# Clean APT
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Configuration
RUN mkdir -p /etc/service/taiga-backend && sed -i '/SHELL/i MAILTO=""' /etc/crontab && \
    (crontab -l; echo "@midnight /home/app/backup >> /var/log/backup.log 2>&1") | crontab -
COPY ./services/taiga-backend.sh /etc/service/taiga-backend/run
COPY ./conf/backend.py /home/app/taiga/backend/settings/local.py
COPY ./conf/passenger_wsgi.py /home/app/taiga/backend/passenger_wsgi.py
COPY ./conf/Passengerfile.json /home/app/taiga/backend/Passengerfile.json
COPY ./scripts/configure.sh /etc/my_init.d/configure.sh
COPY ./scripts/wait-for-it.sh /usr/local/bin/wait-for-it
COPY ./scripts/backup.sh /home/app/backup
RUN chmod +x /etc/my_init.d/configure.sh /usr/local/bin/wait-for-it \
    /etc/service/taiga-backend/run /home/app/backup

# Workaround for missing group name specified in the logrotate configuration
RUN sed -i '/su root syslog/s/syslog/adm/' /etc/logrotate.conf

VOLUME /home/app/taiga/static /home/app/taiga/media

EXPOSE 8000

CMD ["/sbin/my_init"]
