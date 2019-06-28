FROM ubuntu:xenial
MAINTAINER Tõnis Ormisson <tonis@andmemasin.eu>

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
RUN echo mysql-server mysql-server/root_password password root | debconf-set-selections;\
    echo mysql-server mysql-server/root_password_again password root | debconf-set-selections;\
    apt-get install -y mysql-server mysql-client libmysqlclient-dev

# start mysql
RUN sed -i -e"s/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf
RUN find /var/lib/mysql -type f -exec touch {} \; && service mysql start

## aallow mysql user connections from any host
RUN find /var/lib/mysql -type f -exec touch {} \; && service mysql start && service mysql start && mysql -uroot -proot mysql  -e "update user set host='%' where user='root' and host='localhost';flush privileges; CREATE DATABASE test;"



# install php
RUN LC_ALL=C.UTF-8  add-apt-repository ppa:ondrej/php
RUN DEBIAN_FRONTEND=noninteractive apt update && apt install -y php7.2 php7.2-fpm php7.2-cli php7.2-mysql php7.2-curl php7.2-gd \
    php7.2-imap php7.2-zip php7.2-ldap php7.2-xml php7.2-mbstring php7.2-intl php7.2-soap php7.2-bcmath

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
RUN apt install php7.2-xdebug
COPY xdebug/xdebug.ini /usr/local/etc/php/conf.d/xdebug-dev.ini

#dumb-init
RUN wget https://github.com/Yelp/dumb-init/releases/download/v1.2.1/dumb-init_1.2.1_amd64.deb
RUN dpkg -i dumb-init_*.deb

# add bitbucket & github as known hosts
RUN mkdir /root/.ssh
RUN ssh-keyscan bitbucket.org >> /root/.ssh/known_hosts
RUN ssh-keyscan github.com >> /root/.ssh/known_hosts
RUN chmod -R 600 /root/.ssh


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

CMD ["dumb-init", "--", "/start.sh"]
