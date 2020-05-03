#!/bin/bash

source /scripts/func.sh
WORKDIR=$TARS_INSTALL
INSTALL_PATH=/usr/local/app
TARS_PATH=${INSTALL_PATH}/tars
DEPLOY_PATH=${TARS_PATH}/deploy
UPLOAD_PATH=$INSTALL_PATH
WEB_PATH=$INSTALL_PATH
MYSQL_TOOL=${WORKDIR}/mysql-tool

TARSALL="tarsregistry tarsAdminRegistry tarsconfig tarsnode tarslog tarsnotify  tarspatch  tarsproperty tarsqueryproperty tarsquerystat  tarsstat"

mkdir -p ${DEPLOY_PATH}/framework/sql

cp ${WORKDIR}/mysql-tool ${DEPLOY_PATH}

cp -rf ${WORKDIR}/framework/conf ${DEPLOY_PATH}/framework
cp -rf ${WORKDIR}/framework/util-linux ${DEPLOY_PATH}/framework/util
cp -rf ${WORKDIR}/framework/sql ${DEPLOY_PATH}/framework
cp -rf ${WORKDIR}/web/sql/*.sql ${DEPLOY_PATH}/framework/sql/
cp -rf ${WORKDIR}/web/demo/sql/*.sql ${DEPLOY_PATH}/framework/sql/

for var in $TARSALL;
do
    replacePath TARS_PATH ${TARS_PATH} ${DEPLOY_PATH}/framework/conf/${var}/conf
    replacePath TARS_PATH ${TARS_PATH} ${DEPLOY_PATH}/framework/util/${var}/util

    cp -rf ${WORKDIR}/framework/servers/${var} ${TARS_PATH}
done

cp -rf ${WORKDIR}/framework/util-linux/*.sh ${TARS_PATH}

replace TARS_PATH ${TARS_PATH} "${TARS_PATH}/*.sh"
replace WEB_PATH ${WEB_PATH} "${TARS_PATH}/*.sh"

####### install web #############
mkdir -p ${DEPLOY_PATH}/web/demo

rm -rf ${WORKDIR}/web/log

cp -rf ${WORKDIR}/web ${WEB_PATH}
cp -rf ${WORKDIR}/web/config ${DEPLOY_PATH}/web
cp -rf ${WORKDIR}/web/demo/config ${DEPLOY_PATH}/web/demo

###### clean #############
rm -rf ${WORKDIR}
