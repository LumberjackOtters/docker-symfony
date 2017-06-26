FROM php:5.6.30-fpm
MAINTAINER Alexandre Lalung <lalung.alexandre@gmail.com>

ENV NGINX_VERSION 1.12.0-1~jessie
ENV NJS_VERSION   1.12.0.0.1.10-1~jessie

RUN set -ex \
	&& apt-key adv --keyserver hkp://pgp.mit.edu:80 --recv-keys 573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62 \
	&& echo "deb http://nginx.org/packages/debian/ jessie nginx" > /etc/apt/sources.list.d/nginx.list

RUN apt-get update \
	&& apt-get install --no-install-recommends --no-install-suggests -qy \
	# NGINX
		nginx=${NGINX_VERSION} \
		nginx-module-xslt=${NGINX_VERSION} \
		nginx-module-geoip=${NGINX_VERSION} \
		nginx-module-image-filter=${NGINX_VERSION} \
		nginx-module-njs=${NJS_VERSION} \
		gettext-base \
	# PHP extensions dependencies
		# intl
		libicu-dev \
		# mcrypt
		libmcrypt-dev \
		# gd
		libfreetype6-dev \
        libjpeg62-turbo-dev \
		libpng12-dev \
	# supervisor
		supervisor \
	&& rm -rf /var/lib/apt/lists/*

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log

# PHP extensions
RUN set -ex \
	&& pecl install apcu-4.0.8 \
	&& docker-php-ext-enable apcu \
	&& docker-php-ext-configure gd --with-freetype-dir --with-png-dir --with-jpeg-dir \
	&& docker-php-ext-install -j$(nproc) intl mcrypt

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY php.ini /usr/local/etc/php/php.ini
COPY custom-fpm.conf /usr/local/etc/php-fpm.d/custom.conf
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["supervisord"]