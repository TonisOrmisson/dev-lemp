# dev-lemp

A Docker LEMP image for development and testing.

## Environment

- Ubuntu 24.04 LTS, with current security updates at build time
- PHP 8.4 FPM
- nginx 1.30 stable
- MariaDB 11.8 LTS
- Node.js 24 LTS

For testing:

- Xdebug 3
- Selenium Server 4.46
- Firefox stable and geckodriver 0.37
- PHPUnit

## Example

```sh
docker run -d --network=dev1 --name lemptest -p 8888:80 tonisormisson/dev-lemp:1.3.0
```
