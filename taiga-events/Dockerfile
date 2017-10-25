FROM phusion/passenger-customizable:0.9.23

MAINTAINER Sergio Abramchuk <ss.abramchuk@gmail.com>

ENV HOME=/root \
    DEBIAN_FRONTEND=noninteractive

# Replace shell with bash so we can source files
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# Install dependencies
RUN curl -sL https://deb.nodesource.com/setup_7.x | bash - && \
    apt-get update && apt-get install -y python3 python3-pip nodejs && \
    ln -s $(command -v python3) /usr/local/bin/python && \
    ln -s $(command -v pip3) /usr/local/bin/pip && \
    pip install envtpl && npm install -g coffee-script

# Intstall Taiga events
RUN mkdir -p /home/app/taiga && \
    git clone https://github.com/taigaio/taiga-events.git /home/app/taiga/events && \
    cd /home/app/taiga/events && \
    npm install && coffee -c .

# Clean APT
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Configuration
RUN mkdir -p /home/app/taiga/conf-template /etc/service/taiga-events
COPY ./services/taiga-events.sh /etc/service/taiga-events/run
COPY ./conf/events.conf.j2 /home/app/taiga/conf-template/events.conf.j2
COPY ./conf/Passengerfile.json /home/app/taiga/events/Passengerfile.json
COPY ./scripts/configure.sh /etc/my_init.d/configure.sh
RUN chmod +x /etc/my_init.d/configure.sh /etc/service/taiga-events/run

# Workaround for missing group name specified in the logrotate configuration
RUN sed -i '/su root syslog/s/syslog/adm/' /etc/logrotate.conf

EXPOSE 9000

CMD ["/sbin/my_init"]
