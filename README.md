# Docker for PHP Symfony

This image provides the following services:

- php 5.6 with FPM
- nginx 1.12

along with the following tools or frameworks:

- [composer](https://getcomposer.org/)
- [symfony](http://symfony.com/)
- [nodejs LTS](https://nodejs.org/)
- [yarn](https://yarnpkg.com/)

## Create a new Symfony application

You can use the image to create a new Symfony application:

    docker run --rm -u $(id -u):$(id -g) -v $PWD:$HOME -w $HOME purplebabar/symfony symfony new myapp
    cd myapp/

## Run your Symfony application

You can use the image to run your application in development.
Mount your Symfony folder into `/var/www/symfony` and run the container:

    docker run --name myapp -d -v $PWD:/var/www/symfony -p 8080:80 purplebabar/symfony

Your application will run live at [http://localhost:8080]()

## Use Symfony console and Composer

You can execute Symfony console commands on a running container:

    docker exec -ti myapp bin/console cache:clear

or even Composer:

    docker exec -ti myapp composer require doctrine/doctrine-bundle

## Create a custom Docker image for your application

You may ship your Symfony application in a custom Docker image using a `Dockerfile` like the following:

    FROM purplebabar/symfony

    COPY . /var/www/symfony
    composer install --prefer-dist --no-suggest --no-progress --no-dev
    bin/console cache:clear --env=prod --no-debug --no-warmup
    bin/console cache:warmup --no-debug
