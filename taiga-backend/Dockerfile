FROM ssabramchuk/passenger-docker:latest

MAINTAINER Sergio Abramchuk <ss.abramchuk@gmail.com>

ENV HOME=/root \
    DEBIAN_FRONTEND=noninteractive \
    TAIGA_VERSION=2.0.0

# Install dependencies
RUN apt-get update && apt-get install -y \
    libjpeg-dev libxml2-dev libxslt-dev libpq-dev gettext postgresql-client \
    python3 python3-pip python3-dev && ln -s $(which python3) /usr/bin/python && \
    pip3 install envtpl

# Install Taiga backend
RUN mkdir -p /home/app/taiga && \
    git clone https://github.com/taigaio/taiga-back.git /home/app/taiga/backend && \
    mkdir -p /home/app/taiga/media /home/app/taiga/static && \
    cd /home/app/taiga/backend && git checkout $TAIGA_VERSION && \
    pip3 install -r requirements.txt

# Clean APT
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Configuration
RUN mkdir -p /home/app/taiga/conf-template /etc/service/taiga-backend
COPY ./services/taiga-backend.sh /etc/service/taiga-backend/run
COPY ./conf/backend.conf.j2 /home/app/taiga/conf-template/backend.conf.j2
COPY ./conf/passenger_wsgi.py /home/app/taiga/backend/passenger_wsgi.py
COPY ./conf/Passengerfile.json /home/app/taiga/backend/Passengerfile.json
COPY ./scripts/configure.sh /etc/my_init.d/configure.sh
COPY ./scripts/wait-for-it.sh /usr/local/bin/wait-for-it
RUN chmod +x /etc/my_init.d/configure.sh /usr/local/bin/wait-for-it /etc/service/taiga-backend/run

VOLUME /home/app/taiga/static /home/app/taiga/media

EXPOSE 8000

CMD ["/sbin/my_init"]
