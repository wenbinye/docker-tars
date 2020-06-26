FROM centos:7

RUN yum install -y yum-utils psmisc net-tools wget unzip telnet \
    && yum clean all && rm -rf /var/cache/yum

RUN yum install -y http://rpms.remirepo.net/enterprise/remi-release-7.rpm \
    && yum install -y php72-php-cli php72-php-pdo php72-php-pecl-mysql php72-php-xml php72-php-pecl-redis php72-php-pecl-igbinary \
    && yum clean all && rm -rf /var/cache/yum \
    && ln -sf /usr/bin/php72 /usr/bin/php \
    && wget -O-  https://github.com/wenbinye/docker-tars/releases/download/0.1.0/phptars.so.gz | zcat > /opt/remi/php72/root/usr/lib64/php/modules/phptars.so \
    && echo extension=phptars.so > /etc/opt/remi/php72/php.d/20-phptars.ini \
    && wget -O-  https://github.com/wenbinye/docker-tars/releases/download/0.1.0/swoole.so.gz | zcat > /opt/remi/php72/root/usr/lib64/php/modules/swoole.so \
    && echo extension=swoole.so > /etc/opt/remi/php72/php.d/20-swoole.ini

RUN wget https://github.com/wenbinye/docker-tars/releases/download/v2.4.2/tars-bin-2.4.2.tar.gz \
    && tar xf tars-bin-2.4.2.tar.gz -C /usr/local \
    && rm -f tars-bin-2.4.2.tar.gz

RUN wget https://github.com/nvm-sh/nvm/archive/v0.35.1.zip \
    && unzip v0.35.1.zip -d $HOME && rm -f nvm-v0.35.1.zip \
    && ln -sfn $HOME/nvm-0.35.1 $HOME/.nvm \
    && echo 'NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"; [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion";' >> $HOME/.bashrc \
    && source $HOME/.bashrc \
    && NODE_VERSION="v12.13.0" \
    && MIRROR=http://mirrors.cloud.tencent.com \
    && export NVM_NODEJS_ORG_MIRROR=${MIRROR}/nodejs-release \
    && nvm install ${NODE_VERSION}; nvm use --delete-prefix ${NODE_VERSION} \
    && npm config set registry ${MIRROR}/npm/ \
    && npm install -g npm pm2 \
    && cd /usr/local/app/web && npm install \
    && cd demo && npm install

COPY scripts /scripts

ENTRYPOINT [ "/scripts/docker-init.sh" ]

EXPOSE 3000 3001 18993 18793 18693 18193 18593 18493 18393 18293 12000 19386 17890 17891
