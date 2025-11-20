FROM ubuntu:noble
MAINTAINER Tõnis Ormisson <tonis@andmemasin.eu>

## for apt to be noninteractive
ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true

## preesed tzdata, update package index, upgrade packages and install needed software
RUN truncate -s0 /tmp/preseed.cfg; \
    echo "tzdata tzdata/Areas select Europe" >> /tmp/preseed.cfg; \
    echo "tzdata tzdata/Zones/Europe select Berlin" >> /tmp/preseed.cfg; \
    debconf-set-selections /tmp/preseed.cfg && \
    rm -f /etc/timezone /etc/localtime && \
    apt update && \
    apt install -y tzdata && cat /etc/timezone


# update
RUN apt update && apt-get install -y --no-install-recommends apt-utils systemd

# generic tools
RUN apt install -y nano wget net-tools git unzip curl iputils-ping telnet dnsutils nmap \
    software-properties-common apt-transport-https

# nginx
RUN apt install -y nginx

## nginx conf
COPY nginx/default /etc/nginx/sites-available/default

# Install MySQL
RUN echo mariadb-server mariadb-server/root_password password root | debconf-set-selections;\
    echo mariadb-server mariadb-server/root_password_again password root | debconf-set-selections;\
    apt-get install -y mariadb-server mariadb-client libmysqlclient-dev

# start mysql
RUN grep -e bind-address -r /etc/mysql
RUN sed -i -e"s/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/" /etc/mysql/mariadb.conf.d/50-server.cnf
RUN grep -e bind-address -r /etc/mysql

## allow mysql user connections from any host
RUN service mariadb start && mysql -e "RENAME USER 'root'@'localhost' TO 'root'@'%';"
RUN service mariadb start && mysql -e "ALTER USER 'root'@'%' IDENTIFIED BY 'root';"
RUN service mariadb start && mysql -uroot -proot -e "DELETE FROM mysql.user WHERE User='';"
RUN service mariadb start && mysql -uroot -proot -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1', '%');"
RUN service mariadb start && mysql -uroot -proot -e "DROP DATABASE IF EXISTS test;"
RUN service mariadb start && mysql -uroot -proot -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
RUN service mariadb start && mysql -uroot -proot -e "FLUSH PRIVILEGES;"
RUN service mariadb start && mysql -uroot -proot -e "show databases;"


# install php
RUN LC_ALL=C.UTF-8  add-apt-repository ppa:ondrej/php
RUN DEBIAN_FRONTEND=noninteractive apt update && apt install -y php8.3 php8.3-fpm php8.3-cli php8.3-mysql php8.3-curl php8.3-gd \
    php8.3-imap php8.3-zip php8.3-ldap php8.3-xml php8.3-mbstring php8.3-intl php8.3-soap php8.3-bcmath

# raise PHP upload/post limits for large files
RUN printf "upload_max_filesize = 256M\npost_max_size = 256M\nmemory_limit = 512M\n" \
    | tee /etc/php/8.3/fpm/conf.d/uploads.ini /etc/php/8.3/cli/conf.d/uploads.ini >/dev/null

# start webserver
RUN service php8.3-fpm start
RUN service nginx restart

# install composer
RUN curl -sS https://getcomposer.org/installer -o composer-setup.php
RUN php composer-setup.php --install-dir=/usr/local/bin --filename=composer
RUN composer -v

# install phpunit
RUN apt -y install phpunit
RUN phpunit --version

# get selenium for testing
RUN wget "https://github.com/mozilla/geckodriver/releases/download/v0.36.0/geckodriver-v0.36.0-linux64.tar.gz"
RUN tar xvzf geckodriver-v0.36.0-linux64.tar.gz
RUN mv geckodriver* /usr/local/bin/
RUN geckodriver --version

RUN wget "https://selenium-release.storage.googleapis.com/3.9/selenium-server-standalone-3.9.1.jar"
RUN apt -y install default-jre
RUN export MOZ_HEADLESS=1 && export MOZ_HEADLESS_WIDTH=1280 && export MOZ_HEADLESS_HEIGHT=1024
RUN java -jar selenium-server-standalone-3.9.1.jar -enablePassThrough false > /dev/null 2> /dev/null &


#install xdebug (code-coverage)
RUN apt install php8.3-xdebug
COPY xdebug/xdebug.ini /usr/local/etc/php/conf.d/xdebug-dev.ini

#dumb-init
RUN wget https://github.com/Yelp/dumb-init/releases/download/v1.2.5/dumb-init_1.2.5_amd64.deb
RUN dpkg -i dumb-init_*.deb

# add bitbucket & github as known hosts
RUN ssh-keyscan bitbucket.org >> /root/.ssh/known_hosts
RUN ssh-keyscan github.com >> /root/.ssh/known_hosts
RUN chmod -R 600 /root/.ssh

RUN apt install -y nodejs npm

# Expose Ports
EXPOSE 443
EXPOSE 80
EXPOSE 3306


COPY start.sh /start.sh
RUN chmod a+x /start.sh

RUN rm -rf /var/www/html/*
ADD html/ /var/www/html/

RUN cat /var/www/html/index.php

## cleanup of files from setup
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY start.sh /start.sh
RUN chmod a+x /start.sh
RUN ls

##WORKDIR /var/www/html


CMD ["dumb-init", "--", "sh", "/start.sh"]
