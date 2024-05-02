# dev-lemp
A docker LEMP image for development &amp; testing

# Environment

 - Ubuntu Jammy 22.04 LTS
 - PHP 8.3 FPM
 - Nginx
 - MariaDb
 
 For testing: 
 - xdebug (for code-coverage)
 - selenium server (for testing)
 - firefox (for headless testing)
 - phpunit 9.5.0
 
# example run
docker run -d --network=dev1 --name lemptest -p 8888:80 tonisormisson/dev-lemp:latest
