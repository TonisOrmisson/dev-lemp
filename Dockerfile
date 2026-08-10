FROM ubuntu:24.04
LABEL maintainer="Tõnis Ormisson <tonis@andmemasin.eu>"

ARG NGINX_VERSION=1.30.4-1~noble
ARG SELENIUM_VERSION=4.46.0
ARG GECKODRIVER_VERSION=0.37.1

ENV DEBIAN_FRONTEND=noninteractive \
    DEBCONF_NONINTERACTIVE_SEEN=true \
    SELENIUM_JAR=/opt/selenium/selenium-server-4.46.0.jar

# Apply current Ubuntu security updates and install the tooling needed by the
# repositories and development stack.
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        apt-transport-https \
        apt-utils \
        ca-certificates \
        curl \
        default-jre \
        dnsutils \
        dumb-init \
        git \
        gnupg \
        iputils-ping \
        nano \
        net-tools \
        nmap \
        openssh-client \
        software-properties-common \
        telnet \
        unzip \
        wget

# Install the current nginx stable release from nginx.org.
RUN install -d -m 0755 /etc/apt/keyrings \
    && curl -fsSL https://nginx.org/keys/nginx_signing.key \
        | gpg --dearmor -o /etc/apt/keyrings/nginx.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nginx.gpg] https://nginx.org/packages/ubuntu/ noble nginx" \
        > /etc/apt/sources.list.d/nginx.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends nginx=${NGINX_VERSION} \
    && sed -i 's/^user .*/user www-data;/' /etc/nginx/nginx.conf
COPY nginx/default /etc/nginx/conf.d/default.conf

# Install the current MariaDB LTS series and configure the development root account.
RUN curl -fsSL https://r.mariadb.com/downloads/mariadb_repo_setup \
        | bash -s -- --mariadb-server-version=mariadb-11.8 \
    && apt-get update \
    && apt-get install -y --no-install-recommends mariadb-client mariadb-server libmariadb-dev \
    && sed -i -E 's/^bind-address\s*=\s*127\.0\.0\.1/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf \
    && service mariadb start \
    && mariadb -uroot -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'root'; CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY 'root'; GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION; DELETE FROM mysql.global_priv WHERE User=''; DROP DATABASE IF EXISTS test; FLUSH PRIVILEGES;"

# Install PHP 8.4 and required extensions.
RUN LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        php8.4 \
        php8.4-bcmath \
        php8.4-cli \
        php8.4-curl \
        php8.4-fpm \
        php8.4-gd \
        php8.4-imap \
        php8.4-intl \
        php8.4-ldap \
        php8.4-mbstring \
        php8.4-mysql \
        php8.4-soap \
        php8.4-xml \
        php8.4-xdebug \
        php8.4-zip \
        phpunit

# Raise PHP upload/post limits for large files.
RUN printf "upload_max_filesize = 256M\npost_max_size = 256M\nmemory_limit = 512M\n" \
        | tee /etc/php/8.4/fpm/conf.d/uploads.ini /etc/php/8.4/cli/conf.d/uploads.ini >/dev/null
COPY xdebug/xdebug.ini /etc/php/8.4/mods-available/xdebug-dev.ini
RUN phpenmod xdebug-dev \
    && service php8.4-fpm start \
    && service nginx restart

# Install Composer and current Node.js LTS.
RUN curl -fsSL https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && composer --version \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
        | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_24.x nodistro main" \
        > /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends nodejs

# Install current Firefox stable for browser tests.
RUN curl -fsSL https://packages.mozilla.org/apt/repo-signing-key.gpg \
        | gpg --dearmor -o /etc/apt/keyrings/packages.mozilla.org.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.gpg] https://packages.mozilla.org/apt mozilla main" \
        > /etc/apt/sources.list.d/mozilla.list \
    && printf "Package: *\nPin: origin packages.mozilla.org\nPin-Priority: 1000\n" \
        > /etc/apt/preferences.d/mozilla \
    && apt-get update \
    && apt-get install -y --no-install-recommends firefox

# Install current Selenium and geckodriver releases.
RUN install -d /opt/selenium \
    && curl -fsSL "https://github.com/SeleniumHQ/selenium/releases/download/selenium-${SELENIUM_VERSION}/selenium-server-${SELENIUM_VERSION}.jar" \
        -o "${SELENIUM_JAR}" \
    && curl -fsSL "https://github.com/mozilla/geckodriver/releases/download/v${GECKODRIVER_VERSION}/geckodriver-v${GECKODRIVER_VERSION}-linux64.tar.gz" \
        -o /tmp/geckodriver.tar.gz \
    && tar -xzf /tmp/geckodriver.tar.gz -C /usr/local/bin \
    && java -jar "${SELENIUM_JAR}" standalone --help >/dev/null \
    && geckodriver --version

# Add Bitbucket and GitHub as known hosts for development checkouts.
RUN install -d -m 700 /root/.ssh \
    && ssh-keyscan bitbucket.org github.com >> /root/.ssh/known_hosts \
    && chmod 600 /root/.ssh/known_hosts

EXPOSE 443 80 3306

COPY start.sh /start.sh
RUN chmod a+x /start.sh \
    && rm -rf /var/www/html/*
ADD html/ /var/www/html/

# Remove package and download caches from the final image.
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

CMD ["dumb-init", "--", "sh", "/start.sh"]
