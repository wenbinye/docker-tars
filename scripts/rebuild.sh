#!/bin/bash

if [ "$MYSQL_USER" == "" ]; then
    MYSQL_USER="root"
fi

if [ "$MYSQL_PORT" == "" ]; then
    MYSQL_PORT="3306"
fi

TARS_PATH=/usr/local/app/tars
DEPLOY_PATH=${TARS_PATH}/deploy
SQL_PATH=${DEPLOY_PATH}/framework/sql
TEMPLATE_PATH=${DEPLOY_PATH}/framework/sql/template
MYSQL_TOOL=${DEPLOY_PATH}/mysql-tool
MYSQLIP=${MYSQL_HOST}
USER=${MYSQL_USER}
PASS=${MYSQL_ROOT_PASSWORD}
PORT=${MYSQL_PORT}

source /scripts/func.sh

MYSQL_VER=`${MYSQL_TOOL} --host=${MYSQL_HOST} --user=${MYSQL_USER} --pass=${MYSQL_ROOT_PASSWORD} --port=${MYSQL_PORT} --version`

echo "mysql version is: $MYSQL_VER"

exec_mysql_script "drop database if exists db_tars"
exec_mysql_script "drop database if exists tars_stat"
exec_mysql_script "drop database if exists tars_property"
exec_mysql_script "drop database if exists db_tars_web"    
exec_mysql_script "drop database if exists db_user_system"    
exec_mysql_script "drop database if exists db_cache_web"

MYSQL_GRANT="SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, RELOAD, PROCESS, REFERENCES, INDEX, ALTER, CREATE TEMPORARY TABLES, LOCK TABLES, EXECUTE, REPLICATION SLAVE, REPLICATION CLIENT, CREATE VIEW, SHOW VIEW, CREATE USER"

if [ `echo $MYSQL_VER|grep ^8.` ]; then
    exec_mysql_script "CREATE USER '${TARS_USER}'@'%' IDENTIFIED WITH mysql_native_password BY '${TARS_PASS}';"
    exec_mysql_script "GRANT ${MYSQL_GRANT} ON *.* TO '${TARS_USER}'@'%' WITH GRANT OPTION;"
    exec_mysql_script "CREATE USER '${TARS_USER}'@'localhost' IDENTIFIED WITH mysql_native_password BY '${TARS_PASS}';"
    exec_mysql_script "GRANT ${MYSQL_GRANT} ON *.* TO '${TARS_USER}'@'localhost' WITH GRANT OPTION;"
    exec_mysql_script "CREATE USER '${TARS_USER}'@'${HOSTIP}' IDENTIFIED WITH mysql_native_password BY '${TARS_PASS}';"
    exec_mysql_script "GRANT ${MYSQL_GRANT} ON *.* TO '${TARS_USER}'@'${HOSTIP}' WITH GRANT OPTION;"
fi

if [ `echo $MYSQL_VER|grep ^5.` ]; then
    exec_mysql_script "grant ${MYSQL_GRANT} on *.* to '${TARS_USER}'@'%' identified by '${TARS_PASS}' with grant option;"
    if [ $? != 0 ]; then
        echo "grant error, exit." 
        exit 1
    fi

    exec_mysql_script "grant ${MYSQL_GRANT} on *.* to '${TARS_USER}'@'localhost' identified by '${TARS_PASS}' with grant option;"
    exec_mysql_script "grant ${MYSQL_GRANT} on *.* to '${TARS_USER}'@'$HOSTIP' identified by '${TARS_PASS}' with grant option;"
    exec_mysql_script "flush privileges;"
fi

echo "create database (db_tars, tars_stat, tars_property, db_tars_web)";

exec_mysql_script "create database db_tars"
exec_mysql_sql db_tars ${SQL_PATH}/db_tars.sql

exec_mysql_script "create database db_tars_web"
exec_mysql_sql db_tars_web ${SQL_PATH}/db_tars_web.sql

exec_mysql_script "create database db_cache_web"
exec_mysql_sql db_cache_web ${SQL_PATH}/db_cache_web.sql

exec_mysql_script "create database db_user_system"
exec_mysql_sql db_user_system ${SQL_PATH}/db_user_system.sql

exec_mysql_script "create database tars_stat"
exec_mysql_script "create database tars_property"


for template_name in `ls ${TEMPLATE_PATH}`
do
    echo "update template: " $template_name

    parent_template="tars.default"
    if [ "$template_name" == "tars.springboot" ]; then
        parent_template="tars.tarsjava.default"
    elif [ "$template_name" == "tars.tarsAdminRegistry" ]; then
        parent_template="tars.framework-db"
    elif [ "$template_name" == "tars.tarsconfig" ]; then
        parent_template="tars.framework-db"
    elif [ "$template_name" == "tars.tarsnotify" ]; then
        parent_template="tars.framework-db"
    elif [ "$template_name" == "tars.tarsproperty" ]; then
        parent_template="tars.framework-db"
    elif [ "$template_name" == "tars.tarsqueryproperty" ]; then
        parent_template="tars.framework-db"
    elif [ "$template_name" == "tars.tarsstat" ]; then
        parent_template="tars.framework-db"
    elif [ "$template_name" == "tars.tarsquerystat" ]; then
        parent_template="tars.framework-db"
    elif [ "$template_name" == "tars.tarsregistry" ]; then
        parent_template="tars.framework-db"
    fi

    exec_mysql_template $parent_template $template_name ${TEMPLATE_PATH}/${template_name} 
done
