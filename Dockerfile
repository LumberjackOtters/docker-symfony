FROM php:5.6-fpm
LABEL maintainer="lalung.alexandre@gmail.com"

ENV NGINX_VERSION 1.14.0-1~stretch
ENV NJS_VERSION   1.14.0.0.2.0-1~stretch

# NGINX
RUN set -x \
	&& apt-get update \
	&& apt-get install --no-install-recommends --no-install-suggests -y gnupg1 apt-transport-https ca-certificates imagemagick \
	&& \
	NGINX_GPGKEY=573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62; \
	found=''; \
	for server in \
		ha.pool.sks-keyservers.net \
		hkp://keyserver.ubuntu.com:80 \
		hkp://p80.pool.sks-keyservers.net:80 \
		pgp.mit.edu \
	; do \
		echo "Fetching GPG key $NGINX_GPGKEY from $server"; \
		apt-key adv --keyserver "$server" --keyserver-options timeout=10 --recv-keys "$NGINX_GPGKEY" && found=yes && break; \
	done; \
	test -z "$found" && echo >&2 "error: failed to fetch GPG key $NGINX_GPGKEY" && exit 1; \
	apt-get remove --purge --auto-remove -y gnupg1 && rm -rf /var/lib/apt/lists/* \
	&& dpkgArch="$(dpkg --print-architecture)" \
	&& nginxPackages=" \
		nginx=${NGINX_VERSION} \
		nginx-module-xslt=${NGINX_VERSION} \
		nginx-module-geoip=${NGINX_VERSION} \
		nginx-module-image-filter=${NGINX_VERSION} \
		nginx-module-njs=${NJS_VERSION} \
	" \
	&& case "$dpkgArch" in \
		amd64|i386) \
# arches officialy built by upstream
			echo "deb https://nginx.org/packages/debian/ stretch nginx" >> /etc/apt/sources.list.d/nginx.list \
			&& apt-get update \
			;; \
		*) \
# we're on an architecture upstream doesn't officially build for
# let's build binaries from the published source packages
			echo "deb-src https://nginx.org/packages/debian/ stretch nginx" >> /etc/apt/sources.list.d/nginx.list \
			\
# new directory for storing sources and .deb files
			&& tempDir="$(mktemp -d)" \
			&& chmod 777 "$tempDir" \
# (777 to ensure APT's "_apt" user can access it too)
			\
# save list of currently-installed packages so build dependencies can be cleanly removed later
			&& savedAptMark="$(apt-mark showmanual)" \
			\
# build .deb files from upstream's source packages (which are verified by apt-get)
			&& apt-get update \
			&& apt-get build-dep -y $nginxPackages \
			&& ( \
				cd "$tempDir" \
				&& DEB_BUILD_OPTIONS="nocheck parallel=$(nproc)" \
					apt-get source --compile $nginxPackages \
			) \
# we don't remove APT lists here because they get re-downloaded and removed later
			\
# reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
# (which is done after we install the built packages so we don't have to redownload any overlapping dependencies)
			&& apt-mark showmanual | xargs apt-mark auto > /dev/null \
			&& { [ -z "$savedAptMark" ] || apt-mark manual $savedAptMark; } \
			\
# create a temporary local APT repo to install from (so that dependency resolution can be handled by APT, as it should be)
			&& ls -lAFh "$tempDir" \
			&& ( cd "$tempDir" && dpkg-scanpackages . > Packages ) \
			&& grep '^Package: ' "$tempDir/Packages" \
			&& echo "deb [ trusted=yes ] file://$tempDir ./" > /etc/apt/sources.list.d/temp.list \
# work around the following APT issue by using "Acquire::GzipIndexes=false" (overriding "/etc/apt/apt.conf.d/docker-gzip-indexes")
#   Could not open file /var/lib/apt/lists/partial/_tmp_tmp.ODWljpQfkE_._Packages - open (13: Permission denied)
#   ...
#   E: Failed to fetch store:/var/lib/apt/lists/partial/_tmp_tmp.ODWljpQfkE_._Packages  Could not open file /var/lib/apt/lists/partial/_tmp_tmp.ODWljpQfkE_._Packages - open (13: Permission denied)
			&& apt-get -o Acquire::GzipIndexes=false update \
			;; \
	esac \
	\
	&& apt-get install --no-install-recommends --no-install-suggests -y \
						$nginxPackages \
						gettext-base

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
		libjpeg-dev \
		libpng-dev \
	# supervisor
		supervisor \
	&& rm -rf /var/lib/apt/lists/*

# forward request and error logs to docker log collector
# RUN install -m 777 /dev/null /var/log/nginx/access.log \
# 	&& install -m 777 /dev/null /var/log/nginx/error.log \
# 	&& ln -sf /dev/stdout /var/log/nginx/access.log \
# 	&& ln -sf /dev/stderr /var/log/nginx/error.log

# PHP extensions
RUN set -ex \
	&& pecl install apcu-4.0.11 \
  && pecl install imagick-3.4.3 \
	&& docker-php-ext-enable apcu \
	&& docker-php-ext-configure gd --with-freetype-dir --with-png-dir --with-jpeg-dir \
	&& docker-php-ext-install -j$(nproc) intl mcrypt pdo pdo_mysql

# Frameworks
RUN set -ex \
	# Symfony
	&& wget -q -O /usr/local/bin/symfony https://symfony.com/installer \
	&& chmod a+x /usr/local/bin/symfony \
    && rm -rf /var/lib/apt/lists/*

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY php.ini /usr/local/etc/php/php.ini
COPY custom-fpm.conf /usr/local/etc/php-fpm.d/z-custom.conf
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Cleaning
RUN apt-get remove --purge --auto-remove -y apt-transport-https ca-certificates && rm -rf /var/lib/apt/lists/* /etc/apt/sources.list.d/nginx.list \
# if we have leftovers from building, let's purge them (including extra, unnecessary build deps)
&& if [ -n "$tempDir" ]; then \
	apt-get purge -y --auto-remove \
	&& rm -rf "$tempDir" /etc/apt/sources.list.d/temp.list; \
fi

WORKDIR /var/www/symfony

EXPOSE 80

CMD ["supervisord"]
