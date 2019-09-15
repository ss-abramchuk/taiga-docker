FROM phusion/passenger-customizable:1.0.7

MAINTAINER Sergio Abramchuk <ss.abramchuk@gmail.com>

ENV HOME=/root \
    DEBIAN_FRONTEND=noninteractive \
    APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=True

# Replace shell with bash so we can source files
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# Install dependencies
RUN /pd_build/nodejs.sh && npm install -g coffeescript

# Intstall Taiga events
RUN mkdir -p /home/app/taiga && \
    git clone https://github.com/taigaio/taiga-events.git /home/app/taiga/events && \
    cd /home/app/taiga/events && \
    npm install && coffee -c .

# Clean APT
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Configuration
RUN mkdir -p /home/app/scripts /home/app/taiga/conf-template /etc/service/taiga-events
COPY ./services/taiga-events.sh /etc/service/taiga-events/run
COPY ./conf/events.conf.erb /home/app/taiga/conf-template/events.conf.erb
COPY ./conf/Passengerfile.json /home/app/taiga/events/Passengerfile.json
COPY ./scripts/fill_configuration.rb /home/app/scripts/fill_configuration
COPY ./scripts/configure.sh /etc/my_init.d/configure.sh
RUN chmod +x /home/app/scripts/fill_configuration /etc/my_init.d/configure.sh /etc/service/taiga-events/run && \
    ln -s /home/app/scripts/fill_configuration /usr/local/bin/fill_configuration

# Workaround for missing group name specified in the logrotate configuration
RUN sed -i '/su root syslog/s/syslog/adm/' /etc/logrotate.conf

EXPOSE 9000

CMD ["/sbin/my_init"]
