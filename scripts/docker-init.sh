#!/bin/bash

if [ "$1" = "rebuild" ]; then
    /scripts/rebuild.sh
    exit
elif [ "$1" != "" ]; then
    exec "$@"
    exit
fi

source /scripts/func.sh
source ~/.bashrc

NODE_VERSION="v12.13.0"

if [ "$MYSQL_USER" == "" ]; then
    MYSQL_USER="root"
fi

if [ "$MYSQL_PORT" == "" ]; then
    MYSQL_PORT="3306"
fi

if [ "$INET" == "" ]; then
   INET=(eth0)
fi

if [ "$SLAVE" != "true" ]; then
    SLAVE="false"
fi

HOSTIP=""
if [ "$DOMAIN" != "" ]; then
  HOSTIP=$DOMAIN
else 
  #获取主机hostip
  for IP in ${INET[@]};
  do
      HOSTIP=`ifconfig | grep ${IP} -A3 | grep inet | grep broad | awk '{print $2}'    `
      echo $HOSTIP $IP
      if [ "$HOSTIP" != "127.0.0.1" ] && [ "$HOSTIP" != "" ]; then
        break
      fi
  done

  if [ "$HOSTIP" == "127.0.0.1" ] || [ "$HOSTIP" == "" ]; then
      echo "HOSTIP:[$HOSTIP], not valid. HOSTIP must not be 127.0.0.1 or empty."
      exit 1
  fi
fi

echo "MYSQL_HOST=${MYSQL_HOST}"
echo "MYSQL_USER=${MYSQL_USER}"
echo "MYSQL_PORT=${MYSQL_PORT}"
echo "INET=${INET}"
echo "SLAVE=${SLAVE}"
echo "DOMAIN=${DOMAIN}"
echo "HOSTIP=${HOSTIP}"

INSTALL_PATH=/usr/local/app
TARS_PATH=${INSTALL_PATH}/tars
DEPLOY_PATH=${TARS_PATH}/deploy
MYSQL_TOOL=${DEPLOY_PATH}/mysql-tool
SQL_PATH=${DEPLOY_PATH}/framework/sql
MYSQLIP=${MYSQL_HOST}
USER=${MYSQL_USER}
PASS=${MYSQL_ROOT_PASSWORD}
PORT=${MYSQL_PORT}
if [ "${SLAVE}" != "true" ]; then
    TARS="tarsAdminRegistry tarsregistry tarsconfig tarsnode tarsnotify tarsproperty tarsqueryproperty tarsquerystat tarsstat tarslog tarspatch"
else
    TARS="tarsregistry tarsconfig tarsnode tarsnotify tarsproperty tarsqueryproperty tarsquerystat tarsstat"
fi

function rebuild_db_if_not_exists() {
    if [ "${SLAVE}" != "true" ]; then
        exec_mysql_has "db_tars"
        if [ $? != 0 ]; then
            echo "no db_tars exists, begin rebuild db..."
            /scripts/rebuild.sh
        fi
    fi    
}

function update_db_node_info() {
    TMP=/tmp/tars-sql
    rm -rf $TMP && mkdir -p $TMP
    cp -rf ${SQL_PATH}/* $TMP
    
    replacePath localip.tars.com $HOSTIP ${TMP}

    if [ "${SLAVE}" != "true" ]; then
        exec_mysql_sql db_tars $TMP/tars_servers_master.sql
    fi

    exec_mysql_sql db_tars $TMP/tars_servers.sql
    exec_mysql_sql db_tars $TMP/tars_node_init.sql

    rm -rf $TMP
}

function start_server() {
    for var in $TARS;
    do
        if [ ! -d ${TARS_PATH}/${var} ]; then
            LOG_ERROR "${TARS_PATH}/${var} not exist."
            exit 1 
        fi

        echo "update config: ${TARS_PATH}/${var}/conf"
        cp -rf ${DEPLOY_PATH}/framework/conf/${var}/conf ${TARS_PATH}/${var}
        update_conf "${TARS_PATH}/${var}/conf"

        echo "update util: ${TARS_PATH}/${var}/util"
        cp -rf ${DEPLOY_PATH}/framework/util/${var}/util ${TARS_PATH}/${var}
        update_util "${TARS_PATH}/${var}/util"

        echo "remove config: rm -rf ${TARS_PATH}/tarsnode/data/tars.${var}/conf/tars.${var}.config.conf"

        rm -rf ${TARS_PATH}/tarsnode/data/tars.${var}/conf/tars.${var}.config.conf

        echo ${TARS_PATH}/${var}/util/start.sh
        ${TARS_PATH}/${var}/util/start.sh > /dev/null
    done
}

function create_web_files () {
    if ! [ -d ${WEB_PATH}/web ]; then
        echo "web is not install"
        return
    fi
    
    TMP=/tmp/tars-servers
    rm -rf $TMP && mkdir -p $TMP
    cd $TMP
    mkdir -p ${WEB_PATH}/web/files/

    for var in $TARSALL;
    do
        if [ -f ${WEB_PATH}/web/files/${var}.tgz ]; then
            echo "${WEB_PATH}/web/files/${var}.tgz exists"
        else
            cp -rf ${DEPLOY_PATH}/framework/conf $var
            cp -rf ${DEPLOY_PATH}/framework/util $var
            cp -rf ${TARS_PATH}/bin $var
            cp -rf ${TARS_PATH}/data $var

            echo "tar czf ${var}.tgz ${var}"
            tar czf ${var}.tgz ${var}
            cp -rf ${var}.tgz ${WEB_PATH}/web/files/
            rm -rf ${var}.tgz
        fi

    done
    cd $WORKDIR
    rm -rf $TMP
}

function start_web() {
    echo "update web config: ${WEB_PATH}/web/config"
    cp -rf ${DEPLOY_PATH}/web/config ${WEB_PATH}/web
    update_conf ${WEB_PATH}/web/config
    
    echo "update web demo config: ${WEB_PATH}/web/demo/config"
    cp -rf ${DEPLOY_PATH}/web/demo/config ${WEB_PATH}/web/demo
    update_conf ${WEB_PATH}/web/demo/config
    
    cd ${WEB_PATH}/web; pm2 -s stop tars-node-web ; pm2 -s delete tars-node-web; npm run prd; 
    cd ${WEB_PATH}/web/demo; pm2 -s stop tars-user-system;  pm2 -s delete tars-user-system; npm run prd
}

trap 'exit' SIGTERM SIGINT

/scripts/wait-for-it.sh "$MYSQL_HOST:${MYSQL_PORT}"

rebuild_db_if_not_exists
update_db_node_info
start_server

if [ "$SLAVE" != "true" ]; then
    create_web_files
    start_web
fi

echo "install tars success. begin check server..."
if [ "$SLAVE" != "true" ]; then
  TARS=(tarsAdminRegistry  tarsnode  tarsregistry)
else
  TARS=(tarsnode tarsregistry)
fi

while [ 1 ]
do
    sh ${INSTALL_PATH}/tars/tarsnode/util/monitor.sh
    sleep 3
done
