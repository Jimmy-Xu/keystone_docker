#!/bin/bash
#set -e

echo "========================= check env ========================="

echo "> check KEYSTONE_DB_HOST"
if [ -n "$MYSQL_PORT_3306_TCP_PORT" ]; then
	if [ -z "$KEYSTONE_DB_HOST" ]; then
		KEYSTONE_DB_HOST='mysql'
	else
		echo >&2 'warning: both KEYSTONE_DB_HOST and MYSQL_PORT_3306_TCP_PORT found'
		echo >&2 "  Connecting to KEYSTONE_DB_HOST ($KEYSTONE_DB_HOST)"
		echo >&2 '  instead of the linked mysql container'
	fi
fi
if [ -z "$KEYSTONE_DB_HOST" ]; then
	echo >&2 'error: missing KEYSTONE_DB_HOST and MYSQL_PORT_3306_TCP_PORT environment variables'
	echo >&2 '  Did you forget to --link some_mysql_container:mysql or set an external db'
	echo >&2 '  with -e KEYSTONE_DB_HOST=hostname:port?'
	exit 1
fi


echo "> check KEYSTONE_DB_USER and KEYSTONE_DB_PASSWORD"
# if we're linked to MySQL and thus have credentials already, let's use them
: ${KEYSTONE_DB_USER:=${MYSQL_ENV_MYSQL_USER:-root}}
if [ "$KEYSTONE_DB_USER" = 'root' ]; then
	: ${KEYSTONE_DB_PASSWORD:=$MYSQL_ENV_MYSQL_ROOT_PASSWORD}
fi
: ${KEYSTONE_DB_PASSWORD:=$MYSQL_ENV_MYSQL_PASSWORD}
: ${KEYSTONE_DB_NAME:=${MYSQL_ENV_MYSQL_DATABASE:-keystone}}

if [ -z "$KEYSTONE_DB_PASSWORD" ]; then
	echo >&2 'error: missing required KEYSTONE_DB_PASSWORD environment variable'
	echo >&2 '  Did you forget to -e KEYSTONE_DB_PASSWORD=... ?'
	echo >&2
	echo >&2 '  (Also of interest might be KEYSTONE_DB_USER and KEYSTONE_DB_NAME.)'
	exit 1
fi


KEYSTONE_CFG="/etc/keystone/keystone.conf"
echo "> modify ${KEYSTONE_CFG}"
if [ -f ${KEYSTONE_CFG} ];then
	grep "^connection =" ${KEYSTONE_CFG}
	if [ $? -eq 0 ];then
		echo "update connection"
		sed -r -i "s/^connection =.*/connection = mysql:\/\/${KEYSTONE_DB_USER}:${KEYSTONE_DB_PASSWORD}@${KEYSTONE_DB_HOST}\/${KEYSTONE_DB_NAME}/" ${KEYSTONE_CFG}
	else
		grep "#connection =" ${KEYSTONE_CFG}
		if [ $? -eq 0 ];then
			echo "insert connection"
			sed -i "/#connection = <None>/ a connection = mysql://${KEYSTONE_DB_USER}:${KEYSTONE_DB_PASSWORD}@${KEYSTONE_DB_HOST}/${KEYSTONE_DB_NAME}" ${KEYSTONE_CFG}	
		else
			echo "can not find 'connection' under [database] section"
			exit 1
		fi
	fi
else
	echo "${KEYSTONE_CFG} not found"
	exit 1
fi

echo "----------------------------------------"
echo "KEYSTONE_DB_USER    : $KEYSTONE_DB_USER"
echo "KEYSTONE_DB_PASSWORD: $KEYSTONE_DB_PASSWORD"
echo "KEYSTONE_DB_HOST    : $KEYSTONE_DB_HOST"
echo "KEYSTONE_DB_NAME    : $KEYSTONE_DB_NAME"
echo "MYSQL_ENV_MYSQL_ROOT_PASSWORD: $MYSQL_ENV_MYSQL_ROOT_PASSWORD"
echo "MYSQL_PORT_3306_TCP_PORT     : $MYSQL_PORT_3306_TCP_PORT"
echo "MYSQL_PORT_3306_TCP_ADDR     : $MYSQL_PORT_3306_TCP_ADDR"
echo "----------------------------------------"

function fn_quit(){
	if [ $1 -ne 0 ];then
		echo $2
		exit 1
	fi
}

echo "========================= connect database ========================="
LOOP_LIMIT=10
for (( i=0 ; ; i++ )); do
    if [ ${i} -eq ${LOOP_LIMIT} ]; then
        echo "Time out. Error log is shown as below:"
        tail -n10 /var/log/mysql/error.log
        fn_quit $? "can not connect to mysql"
    fi
    mysql -uroot -p${MYSQL_ENV_MYSQL_ROOT_PASSWORD} -h ${KEYSTONE_DB_HOST} -e "status" > /dev/null 2>&1 && echo "mysql is OK" && break
    echo "=> Waiting for confirmation of MySQL service startup, trying ${i}/${LOOP_LIMIT}, wait 6 seconds ..."
    sleep 6; \
done


echo "> check database"
mysql -uroot -p${MYSQL_ENV_MYSQL_ROOT_PASSWORD} -h ${KEYSTONE_DB_HOST} -e "show databases" | grep ${KEYSTONE_DB_NAME}
if [ $? -ne 0 ];then
	echo "${KEYSTONE_DB_NAME} not found, re-create database now..."
	echo "  > create db: ${KEYSTONE_DB_NAME}"
	mysql -uroot -p${MYSQL_ENV_MYSQL_ROOT_PASSWORD} -h ${KEYSTONE_DB_HOST} -e "create database ${KEYSTONE_DB_NAME}; grant all on ${KEYSTONE_DB_NAME}.* to '${KEYSTONE_DB_USER}'@'%' identified by '${KEYSTONE_DB_PASSWORD}'; FLUSH PRIVILEGES;"
	fn_quit $? "create& init keystone db failed"
fi

echo "> check tables"
TBL_CNT=$(mysql -uroot -p${MYSQL_ENV_MYSQL_ROOT_PASSWORD} -h ${KEYSTONE_DB_HOST} -e "use ${KEYSTONE_DB_NAME};show tables" | wc -l)
if [ ${TBL_CNT} -eq 0 ];then
	echo "tables in ${KEYSTONE_DB_NAME} not found, re-create tables now..."
	echo "  > create tables in keystone db"
	keystone-manage db_sync
	fn_quit $? "db_sync failed"
fi
echo "  >init keystone database succeed"

echo "> show connection in /etc/keystone/keystone.conf"
cat /etc/keystone/keystone.conf | grep "^connection ="

echo "> start execute CMD: $@"
exec "$@"
