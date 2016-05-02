FROM phusion/baseimage:0.9.18

MAINTAINER Sergio Abramchuk <ss.abramchuk@gmail.com>

ENV HOME=/root \
    DEBIAN_FRONTEND=noninteractive \
    TAIGA_VERSION=2.0.0

# Install dependencies
RUN apt-get update && apt-get install -y nginx git && \
    curl "https://bootstrap.pypa.io/get-pip.py" -o "/tmp/get-pip.py" && \
    python3 /tmp/get-pip.py && pip install envtpl

# Install Taiga frontend
RUN mkdir -p /home/app/taiga /home/app/taiga/media /home/app/taiga/static && \
    git clone https://github.com/taigaio/taiga-front-dist.git /home/app/taiga/frontend && \
    cd /home/app/taiga/frontend && git checkout $TAIGA_VERSION

# Clean APT
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Configuration
RUN mkdir -p /home/app/taiga/conf-template /etc/nginx/certs /etc/service/nginx /etc/service/nginx-log-forwarder && \
    rm -f /etc/nginx/sites-enabled/default
COPY ./services/nginx.sh /etc/service/nginx/run
COPY ./services/nginx-log-forwarder.sh /etc/service/nginx-log-forwarder/run
COPY ./conf/nginx.conf /etc/nginx/nginx.conf
COPY ./conf/vhost.conf.j2 /home/app/taiga/conf-template/vhost.conf.j2
COPY ./conf/frontend.conf.j2 /home/app/taiga/conf-template/frontend.conf.j2
COPY ./scripts/configure.sh /etc/my_init.d/configure.sh
RUN chmod +x /etc/my_init.d/configure.sh /etc/service/nginx/run /etc/service/nginx-log-forwarder/run

EXPOSE 80 443

CMD ["/sbin/my_init"]
