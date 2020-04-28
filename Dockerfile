FROM centos:7

COPY winwin.repo /etc/yum.repos.d/
COPY sh.local /etc/profile.d/sh.local

RUN yum install -y yum-utils psmisc net-tools wget unzip telnet \
        winwin-php72 winwin-php72-swoole winwin-php72-phptars \
    && yum clean all && rm -rf /var/cache/yum

ENV TARS_INSTALL /usr/local/tars/cpp/deploy

RUN mkdir -p ${TARS_INSTALL} && cd ${TARS_INSTALL} \
    && wget https://github.com/wenbinye/docker-tars/releases/download/0.1.0/tars-bin-2.3.0.tar.gz \
    && wget https://github.com/wenbinye/docker-tars/releases/download/0.1.0/tars-web-2.1.0.tar.gz \
    && tar zxf tars-bin-2.3.0.tar.gz \
    && cp -rf tars/cpp/deploy/* . && rm -rf tars \
    && mkdir -p web \
    && tar zxf tars-web-2.1.0.tar.gz -C web 

RUN wget https://github.com/nvm-sh/nvm/archive/v0.35.1.zip;unzip v0.35.1.zip; cp -rf nvm-0.35.1 $HOME/.nvm \
    && echo 'NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"; [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion";' >> $HOME/.bashrc; \
    source $HOME/.bashrc && nvm install v12.13.0

RUN ${TARS_INSTALL}/tar-server.sh

RUN ln -sf /local/service/php72/bin/php /usr/bin/php

COPY wait-for-it.sh /

ENTRYPOINT [ "sh", "-c", "/wait-for-it.sh $MYSQL_HOST:${MYSQL_PORT:-3306} -- $TARS_INSTALL/docker-init.sh" ]

EXPOSE 3000 3001 18993 18793 18693 18193 18593 18493 18393 18293 12000 19385 17890 17891
