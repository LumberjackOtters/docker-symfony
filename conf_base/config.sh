#!/bin/sh

echo Lets bring our virtual hosts up

if [ -e "/var/www/index.php" ]
then
    cp /conf_base/index.php /var/www/index.php
fi

rm /etc/nginx/sites-available/default
ln -s /etc/nginx/sites-available/*.conf /etc/nginx/sites-enabled/
