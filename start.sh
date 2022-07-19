
# Start mysql
service mariadb start
echo "Starting mariadb s"
service mariadb start
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start mariadb: $status"
  exit $status
fi

# Start PHP-fpm
echo "Starting PHP-fpm 8.0 "
service php8.0-fpm start
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start PHP-fpm: $status"
  exit $status
fi

# Start selenium
echo "Starting Selenium ... "
export MOZ_HEADLESS=1 && java -jar selenium-server-standalone-*.jar -enablePassThrough false  > /var/log/selenium.log 2> /var/log/selenium_error.log &
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start Selenium: $status"
  exit $status
fi

# Start nginx
echo "Starting nginx .... "
nginx -g "daemon off;"
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start nginx: $status"
  exit $status
fi
