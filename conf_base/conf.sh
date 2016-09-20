#!/bin/bash

# set max_execution_time
if [ ! -z "$MAX_EXECUTIION_TIME" ]; then
    sed -i".bak" "s/^max_execution_time.*$/max_execution_time = ${MAX_EXECUTIION_TIME} /g" /etc/php5/fpm/php.ini
fi

# set timezone in php.ini
if [ ! -z "$DATE_TIMEZONE" ]; then
    sed -i".bak" "s/^\;date\.timezone.*$/date\.timezone = \"${DATE_TIMEZONE}\" /g" /etc/php5/fpm/php.ini
fi
