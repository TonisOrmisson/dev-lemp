FROM ubuntu:bionic
ENV DEBIAN_FRONTEND noninteractive

# update
RUN apt update && apt-get install -y --no-install-recommends apt-utils

# generic tools
RUN apt install -y nano wget net-tools git unzip curl

# nginx
RUN apt install -y nginx

## nginx conf
COPY nginx/default /etc/nginx/sites-available/default

# Install MySQL
RUN echo mysql-server mysql-server/root_password password root | debconf-set-selections;\
    echo mysql-server mysql-server/root_password_again password root | debconf-set-selections;\
    apt-get install -y mysql-server mysql-client libmysqlclient-dev

# start mysql
RUN sed -i -e"s/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf
RUN find /var/lib/mysql -type f -exec touch {} \; && service mysql start


# install php
RUN apt install -y php-fpm php-cli php-mysql php-curl php-gd php-imap php-zip php-ldap php-xml php-mbstring

# start webserver
RUN service php7.2-fpm start
RUN service nginx restart



# install composer
RUN curl -sS https://getcomposer.org/installer -o composer-setup.php
RUN php composer-setup.php --install-dir=/usr/local/bin --filename=composer
RUN composer

# install phpunit
RUN wget https://phar.phpunit.de/phpunit-6.5.9.phar
RUN chmod +x phpunit-6.5.9.phar
RUN mv phpunit-6.5.9.phar /usr/local/bin/phpunit
RUN phpunit --version


# install firefox for tests
RUN apt -y install npm nodejs firefox
RUN firefox -v

# get selenium for testing
RUN wget "https://selenium-release.storage.googleapis.com/3.13/selenium-server-standalone-3.13.0.jar"
RUN wget "https://github.com/mozilla/geckodriver/releases/download/v0.21.0/geckodriver-v0.21.0-linux64.tar.gz"
RUN tar xvzf geckodriver-v0.21.0-linux64.tar.gz
RUN apt install -y default-jre

#install xdebug (code-coverage)

RUN apk update \
    && apk add  --no-cache libmcrypt libmcrypt-dev \
    && apk add --no-cache --virtual build-dependencies icu-dev \
    libxml2-dev freetype-dev libpng-dev libjpeg-turbo-dev g++ make autoconf \
    && docker-php-source extract \
    && pecl install xdebug \
    && docker-php-ext-enable xdebug redis \
    && docker-php-source delete \
    && apk del build-dependencies \
    && apk del libmcrypt-dev \
    && rm -rf /tmp/*

COPY xdebug.ini /usr/local/etc/php/conf.d/xdebug-dev.ini

# Expose Ports
EXPOSE 443
EXPOSE 80
EXPOSE 3306


COPY start.sh start.sh
RUN chmod a+x start.sh

RUN rm -rf /var/www/html/*
ADD html/ /var/www/html/

RUN cat /var/www/html/index.php
WORKDIR /var/www/html

CMD sh /start.sh
ENV DEBIAN_FRONTEND teletype
