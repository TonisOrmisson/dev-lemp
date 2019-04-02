# dev-lemp
A docker LEMP image for development &amp; testing

# Environment

 - Ubuntu Bionic 18.04 LTS
 - PHP 7.2 FPM
 - Nginx
 - MySql
 
 For testing: 
 - xdebug (for code-coverage)
 - selenium server (for testing)
 - firefox (for headless testing)
 - phpunit
 
# example run
docker run -d --network=dev1 --name lemptest -p 8888:80 tonisormisson/dev-lemp:latest
