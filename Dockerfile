FROM php:5.6-fpm
LABEL maintainer="lalung.alexandre@gmail.com"


RUN apt-get update \
	&& apt-get install --no-install-recommends --no-install-suggests -qy \
		wget \
		gettext-base \
	# PHP extensions dependencies
		# intl
		libicu-dev \
		# mcrypt
		libmcrypt-dev \
		# gd
		libfreetype6-dev \
        libjpeg62-turbo-dev \
		libpng-dev \
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

# Frameworks
RUN set -ex \
	# Symfony
	&& wget -q -O /usr/local/bin/symfony https://symfony.com/installer \
	&& chmod a+x /usr/local/bin/symfony \
	# Composer
	&& wget -q -O /usr/src/composer-installer https://getcomposer.org/installer \
	&& php /usr/src/composer-installer --install-dir /usr/local/bin --filename composer \
	# Nodejs
    && curl -sL https://deb.nodesource.com/setup_6.x | bash - \
    && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
    && apt-get update && apt-get install --no-install-recommends --no-install-suggests -qy \
        nodejs \
        yarn \
    && rm -rf /var/lib/apt/lists/*

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY php.ini /usr/local/etc/php/php.ini
COPY custom-fpm.conf /usr/local/etc/php-fpm.d/z-custom.conf
COPY nginx.conf /etc/nginx/conf.d/default.conf

WORKDIR /var/www/symfony

EXPOSE 80

CMD ["supervisord"]
