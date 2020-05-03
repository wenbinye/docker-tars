FROM centos:7

RUN yum install -y yum-utils psmisc net-tools wget unzip telnet \
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

RUN yum install -y http://rpms.remirepo.net/enterprise/remi-release-7.rpm \
    && yum install -y php72-php-cli \
    && yum clean all && rm -rf /var/cache/yum \
    && ln -sf /usr/bin/php72 /usr/bin/php \
    && wget -O-  https://github.com/wenbinye/docker-tars/releases/download/0.1.0/phptars.so.gz | zcat > /opt/remi/php72/root/usr/lib64/php/modules/phptars.so \
    && echo extension=phptars.so > /etc/opt/remi/php72/php.d/20-phptars.ini \
    && wget -O-  https://github.com/wenbinye/docker-tars/releases/download/0.1.0/swoole.so.gz | zcat > /opt/remi/php72/root/usr/lib64/php/modules/swoole.so \
    && echo extension=swoole.so > /etc/opt/remi/php72/php.d/20-swoole.ini

RUN ${TARS_INSTALL}/tar-server.sh

COPY scripts /scripts

RUN /scripts/tars-install.sh

ENTRYPOINT /scripts/docker-init.sh

EXPOSE 3000 3001 18993 18793 18693 18193 18593 18493 18393 18293 12000 19385 17890 17891
