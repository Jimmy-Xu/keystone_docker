#!/bin/bash

LOOP_LIMIT=5
for (( i=0 ; ; i++ )); do
    if [ ${i} -eq ${LOOP_LIMIT} ]; then
        echo "Time out. Error log is shown as below:"
        tail -n10 /var/log/mysql/error.log
        exit 1
    fi
    mysql -uroot -proot -e "status" > /dev/null 2>&1 && echo "mysql is OK" && break
    echo "=> Waiting for confirmation of MySQL service startup, trying ${i}/${LOOP_LIMIT}, wait 5 seconds ..."
    sleep 5; \
done

