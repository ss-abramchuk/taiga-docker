FROM ssabramchuk/passenger-docker:latest

MAINTAINER Sergio Abramchuk <ss.abramchuk@gmail.com>

ENV HOME=/root \
    DEBIAN_FRONTEND=noninteractive \
    NVM_DIR=/usr/local/nvm \
    NODE_VERSION=0.12

# Replace shell with bash so we can source files
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# Install dependencies
RUN apt-get update && apt-get install -y python-minimal && \
    curl "https://bootstrap.pypa.io/get-pip.py" -o "/tmp/get-pip.py" && \
    python3 /tmp/get-pip.py && pip install envtpl && \
    curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.31.0/install.sh | bash && \
    source $NVM_DIR/nvm.sh && nvm install $NODE_VERSION && npm install -g coffee-script && \
    ln -s $(command -v node) /usr/local/bin/node && \
    ln -s $(command -v npm) /usr/local/bin/npm && \
    ln -s $(command -v coffee) /usr/local/bin/coffee

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

EXPOSE 9000

CMD ["/sbin/my_init"]
