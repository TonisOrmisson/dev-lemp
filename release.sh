docker build --tag tonisormisson/dev-lemp .
docker tag tonisormisson/dev-lemp:latest tonisormisson/dev-lemp:0.7.1
docker push tonisormisson/dev-lemp:0.7.1 && docker push tonisormisson/dev-lemp:latest
