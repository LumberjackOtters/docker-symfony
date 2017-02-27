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
	build-essentials \
	php5-fpm \
	php5-cli \
	php5-intl \
	php5-mcrypt \
	php5-apcu \
	php5-gd \
	php5-curl \
	php5-mysql

RUN groupadd --gid 1000 node \
  && useradd --uid 1000 --gid node --shell /bin/bash --create-home node

# gpg keys listed at https://github.com/nodejs/node
RUN set -ex \
  && for key in \
    9554F04D7259F04124DE6B476D5A82AC7E37093B \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    0034A06D9D9B0064CE8ADF6BF1747F4AD2306D93 \
    FD3A5288F042B6850C66B31F09FE44734EB7990E \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    B9AE9905FFD7803F25714661B63B535A4C206CA9 \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
    56730D5401028683275BD23C23EFEFE93C4CFFFE \
  ; do \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
  done

ENV NPM_CONFIG_LOGLEVEL info
ENV NODE_VERSION 7.6.0

RUN curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz" \
  && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
  && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
  && grep " node-v$NODE_VERSION-linux-x64.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
  && tar -xJf "node-v$NODE_VERSION-linux-x64.tar.xz" -C /usr/local --strip-components=1 \
  && rm "node-v$NODE_VERSION-linux-x64.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
  && ln -s /usr/local/bin/node /usr/local/bin/nodejs

# install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# fix security issue in php.ini, more info https://nealpoole.com/blog/2011/04/setting-up-php-fastcgi-and-nginx-dont-trust-the-tutorials-check-your-configuration/
RUN sed -i.bak "s@;cgi.fix_pathinfo=1@cgi.fix_pathinfo=0@g" /etc/php5/fpm/php.ini

# set max_execution_time
RUN sed -i".bak" "s/^max_execution_time.*$/max_execution_time = 3000 /g" /etc/php5/fpm/php.ini
RUN echo "request_terminate_timeout=3000s" >> /etc/php5/fpm/php-fpm.conf

# set timezone in php.ini
RUN sed -i".bak" "s/^\;date\.timezone.*$/date\.timezone = \"Europe\/Paris\" /g" /etc/php5/fpm/php.ini

# run init script
RUN echo Lets create the root directory
RUN mkdir /var/www
RUN chown -R www-data:www-data /var/www
VOLUME ["/var/www"]
VOLUME ["/etc/nginx/sites-available"]
RUN rm /etc/nginx/sites-available/default
RUN ln -s /etc/nginx/sites-available/info.conf /etc/nginx/sites-enabled/
RUN ln -s /etc/nginx/sites-available/site.conf /etc/nginx/sites-enabled/

# expose port 80
EXPOSE 80

# run nginx and php5-fpm on startup
RUN echo "/etc/init.d/php5-fpm start" >> /etc/bash.bashrc
RUN echo "/etc/init.d/nginx start" >> /etc/bash.bashrc
