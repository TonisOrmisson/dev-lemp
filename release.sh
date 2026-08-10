#!/bin/sh
set -eu

IMAGE=tonisormisson/dev-lemp
VERSION=1.3.0

docker build --pull --tag "$IMAGE:latest" .
docker tag "$IMAGE:latest" "$IMAGE:$VERSION"
docker push "$IMAGE:latest"
docker push "$IMAGE:$VERSION"
