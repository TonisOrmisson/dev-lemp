docker build --tag tonisormisson/dev-lemp .
docker tag tonisormisson/dev-lemp:latest tonisormisson/dev-lemp:0.3.5
docker push tonisormisson/dev-lemp:latest && docker push tonisormisson/dev-lemp:0.3.4