#!/bin/bash

# Start mysql
echo "Starting mysql "
find /var/lib/mysql -type f -exec touch {} \; && service mysql start

# Start PHP-fpm
echo "Starting PHP-fpm "
service php7.4-fpm start

# Start selenium
echo "Starting Selenium ... "
export MOZ_HEADLESS=1 && java -jar selenium-server-standalone-*.jar -enablePassThrough false  > /var/log/selenium.log 2> /var/log/selenium_error.log &

# Start nginx
echo "Starting nginx ... "
nginx -g "daemon off;"

