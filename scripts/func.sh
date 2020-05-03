#!/bin/bash

TARS_USER=tarsAdmin
TARS_PASS=Tars@2019

function kill_all()
{
  if [ $OS == 2 ]; then
    killall -9 $1
  elif [ $OS == 3 ]; then
    killall -q -9 $1
  else
    killall -9 -q $1
  fi
}

function netstat_port()
{
  if [ $OS == 2 ]; then
    netstat -anL
  elif [ $OS == 3 ]; then
    netstat -an -p TCP
  else
    netstat -lpn
  fi
}

#公共函数
function LOG_ERROR()
{
	local msg=$(date +%Y-%m-%d" "%H:%M:%S);

    msg="${msg} $@";

	echo -e "\033[31m $msg \033[0m";	
}

function LOG_WARNING()
{
	local msg=$(date +%Y-%m-%d" "%H:%M:%S);

    msg="${msg} $@";

	echo -e "\033[33m $msg \033[0m";	
}

function LOG_DEBUG()
{
	local msg=$(date +%Y-%m-%d" "%H:%M:%S);

    msg="${msg} $@";

 	echo -e "\033[40;37m $msg \033[0m";	
}

function LOG_INFO()
{
	local msg=$(date +%Y-%m-%d" "%H:%M:%S);
	
	for p in $@
	do
		msg=${msg}" "${p};
	done
	
	echo -e "\033[32m $msg \033[0m"  	
}

################################################################################
#check port
function check_ports()
{
    echo "check port if conflict"
    PORTS="18993 18793 18693 18193 18593 18493 18393 18293 12000 19385 17890 17891 3000 3001"
    for P in $PORTS;
    do
        NETINFO=$(netstat_port)

        RESULT=`echo ${NETINFO} | grep ${HOSTIP}:${P}`
        if [ "$RESULT" != "" ]; then
            LOG_ERROR ${HOSTIP}:${P}", port maybe conflict, please check!"
        fi

        RESULT=`echo ${NETINFO} | grep 127.0.0.1:${P}`
        if [ "$RESULT" != "" ]; then
            LOG_ERROR 127.0.0.1:${P}", port maybe conflict, please check!"
            # exit 1
        fi
    done
}

# check_ports

################################################################################

function check_mysql()
{
    ${MYSQL_TOOL} --host=${MYSQLIP} --user="$1" --pass="$2" --port=${PORT} --check

    if [ $? == 0 ]; then
        echo "mysql is alive"
        return
    fi

    LOG_ERROR "check mysql is not alive: ${MYSQL_TOOL} --host=${MYSQLIP} --user="$1" --pass="$2" --port=${PORT} --check"

    exit 1
}
################################################################################
#check mysql


function exec_mysql_has()
{
    #echo "${MYSQL_TOOL} --host=${MYSQLIP} --user=${USER} --pass=${PASS} --port=${PORT} --charset=utf8 --has=$1"
    ${MYSQL_TOOL} --host=${MYSQLIP} --user=${USER} --pass=${PASS} --port=${PORT} --charset=utf8 --has=$1

    ret=$?
    echo "exec_mysql_has $1, ret: $ret"

    return $ret
}

function exec_mysql_script()
{
    ${MYSQL_TOOL} --host=${MYSQLIP} --user=${USER} --pass=${PASS} --port=${PORT} --charset=utf8 --sql="$1"

    ret=$?
    echo "exec_mysql_script $1, ret code: $ret"  

    return $ret
}

function exec_mysql_sql()
{
    #echo "${MYSQL_TOOL} --host=${MYSQLIP} --user=${USER} --pass=${PASS} --port=${PORT} --charset=utf8 --db=$1 --file=$2"
    ${MYSQL_TOOL} --host=${MYSQLIP} --user=${USER} --pass=${PASS} --port=${PORT} --charset=utf8 --tars-path=${TARS_PATH} --db=$1 --file=$2

    ret=$?

    echo "exec_mysql_sql $1 $2, ret code: $ret"  

    return $ret
}

function exec_mysql_template()
{
    #echo "${MYSQL_TOOL} --host=${MYSQLIP} --user=${USER} --pass=${PASS} --port=${PORT} --charset=utf8 --parent=$1 --template=$2 --profile=$3"
    ${MYSQL_TOOL} --host=${MYSQLIP} --user=${TARS_USER} --pass=${TARS_PASS} --port=${PORT} --charset=utf8 --db=db_tars --upload-path=${UPLOAD_PATH} --tars-path=${TARS_PATH} --parent=$1 --template=$2 --profile=$3

    ret=$?

    echo "exec_mysql_template $1 $2, ret code: $ret"  

    return $ret
}

################################################################################

function replace()
{
    SRC=$1
    DST=$2
    SCAN_FILE=$3

    FILES=`grep "${SRC}" -rl $SCAN_FILE`

    if [ "$FILES" == "" ]; then
        return
    fi

    for file in $FILES;
    do
        ${MYSQL_TOOL} --src="${SRC}" --dst="${DST}" --replace=$file 
    done
}

function replacePath()
{
    SRC=$1
    DST=$2
    SCAN_PATH=$3

    FILES=`grep "${SRC}" -rl $SCAN_PATH/*`

    if [ "$FILES" == "" ]; then
        return
    fi

    for file in $FILES;
    do
        ${MYSQL_TOOL} --src="${SRC}" --dst="${DST}" --replace=$file 
    done
}

################################################################################
#replacePath sql/template

################################################################################

function update_conf() 
{
    for file in `ls $1`;
    do
       ${MYSQL_TOOL} --host=${MYSQLIP} --user="${TARS_USER}" --pass="${TARS_PASS}" --port=${PORT} --config=$1/$file --tars-path=${TARS_PATH} --upload-path=${UPLOAD_PATH} --hostip=${HOSTIP}
    done
}

function update_util()
{
    for file in `ls $1`;
    do
        replace localip.tars.com $HOSTIP $1/${file}
    done
}

function update_web_conf() 
{
    UPDATE_PATH=$1

    replacePath localip.tars.com $HOSTIP ${UPDATE_PATH}
    replacePath db.tars.com $MYSQLIP ${UPDATE_PATH}
    replacePath registry.tars.com $HOSTIP ${UPDATE_PATH}
    replacePath 3306 $PORT ${UPDATE_PATH}
    replacePath "user: 'tars'" "user: '${TARS_USER}'" ${UPDATE_PATH}
    replacePath "password: 'tars2015'" "password: '${TARS_PASS}'" ${UPDATE_PATH}
    replacePath "/usr/local/app" "$WEB_PATH" ${UPDATE_PATH}
    replacePath "enableAuth: false" "enableAuth: true" ${UPDATE_PATH}
    replacePath "enableLogin: false" "enableLogin: true" ${UPDATE_PATH}
}
