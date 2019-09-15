FROM phusion/passenger-customizable:1.0.7

MAINTAINER Sergio Abramchuk <ss.abramchuk@gmail.com>

ENV HOME=/root \
    DEBIAN_FRONTEND=noninteractive \
    TAIGA_VERSION=4.2.12-stable

# Install Taiga frontend
RUN mkdir -p /home/app/taiga /home/app/taiga/media /home/app/taiga/static && \
    git clone https://github.com/taigaio/taiga-front-dist.git /home/app/taiga/frontend && \
    cd /home/app/taiga/frontend && git checkout $TAIGA_VERSION

# Clean APT
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Configuration
RUN rm -f /etc/service/nginx/down
RUN mkdir -p /home/app/scripts /home/app/taiga/conf-template /etc/nginx/certs && \
    sed -i '/passenger.conf/s/include/# include/' /etc/nginx/nginx.conf && \
    rm -f /etc/nginx/sites-enabled/default
COPY ./conf/vhost.conf.erb /home/app/taiga/conf-template/vhost.conf.erb
COPY ./conf/frontend.conf.erb /home/app/taiga/conf-template/frontend.conf.erb
COPY ./conf/proxy-map.conf /etc/nginx/conf.d/proxy-map.conf
COPY ./scripts/fill_configuration.rb /home/app/scripts/fill_configuration
COPY ./scripts/configure.sh /etc/my_init.d/configure.sh
RUN chmod +x /home/app/scripts/fill_configuration /etc/my_init.d/configure.sh && \
    ln -s /home/app/scripts/fill_configuration /usr/local/bin/fill_configuration

# Workaround for missing group name specified in the logrotate configuration
RUN sed -i '/su root syslog/s/syslog/adm/' /etc/logrotate.conf

EXPOSE 80 443

CMD ["/sbin/my_init"]
