#!/bin/sh
set -e

# Start MariaDB.
echo "Starting MariaDB ..."
service mariadb start

# Start PHP-FPM.
echo "Starting PHP-FPM 8.4 ..."
service php8.4-fpm start

# Start Selenium for browser tests.
echo "Starting Selenium ..."
export MOZ_HEADLESS=1
java -jar "$SELENIUM_JAR" standalone \
    > /var/log/selenium.log 2> /var/log/selenium_error.log &

# Keep nginx in the foreground as the container process.
echo "Starting nginx ..."
exec nginx -g "daemon off;"
