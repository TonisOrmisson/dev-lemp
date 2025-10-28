docker build --tag tonisormisson/dev-lemp .
docker tag tonisormisson/dev-lemp:latest tonisormisson/dev-lemp:1.1.0
docker push tonisormisson/dev-lemp --all-tags
