# set the base image first
FROM ubuntu:14.04

# specify maintainer
MAINTAINER Alexandre Lalung <lalung.alexandre@gmail.com>

# run update and install nginx, php-fpm and other useful libraries
RUN apt-get update -y && \
	apt-get install -y \
	nginx \
	curl \
	nano \
	git \
	php5-fpm \
	php5-cli \
	php5-intl \
	php5-mcrypt \
	php5-apcu \
	php5-gd \
	php5-curl

# install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# fix security issue in php.ini, more info https://nealpoole.com/blog/2011/04/setting-up-php-fastcgi-and-nginx-dont-trust-the-tutorials-check-your-configuration/
RUN sed -i.bak "s@;cgi.fix_pathinfo=1@cgi.fix_pathinfo=0@g" /etc/php5/fpm/php.ini

# set timezone in php.ini
RUN sed -i".bak" "s/^\;date\.timezone.*$/date\.timezone = \"Europe\/Paris\" /g" /etc/php5/fpm/php.ini

# Add config files
ADD init /init

# run init script
RUN mkdir /var/www
RUN chown -R www-data:www-data /var/www
VOLUME ["/var/www"]
VOLUME ["/etc/nginx/sites-available"]
RUN cp /init/sample-virtual-host /etc/nginx/sites-available/sample
RUN ln -s /etc/nginx/sites-available/*.conf /etc/nginx/sites-enabled/

# expose port 80
EXPOSE 80

# run nginx and php5-fpm on startup
RUN echo "/etc/init.d/php5-fpm start" >> /etc/bash.bashrc
RUN echo "/etc/init.d/nginx start" >> /etc/bash.bashrc
