# dev-lemp
A docker LEMP image for development &amp; testing

# Environment

 - Ubuntu Bionic 20.04 LTS
 - PHP 7.4 FPM
 - Nginx
 - MySql
 
 For testing: 
 - xdebug (for code-coverage)
 - selenium server (for testing)
 - firefox (for headless testing)
 - phpunit 9.5.0
 
# example run
docker run -d --network=dev1 --name lemptest -p 8888:80 tonisormisson/dev-lemp:latest
