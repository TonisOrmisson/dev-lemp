docker build --tag tonisormisson/dev-lemp .
docker tag tonisormisson/dev-lemp:latest tonisormisson/dev-lemp:1.0.2
docker push tonisormisson/dev-lemp:1.0.2&& docker push tonisormisson/dev-lemp:latest
