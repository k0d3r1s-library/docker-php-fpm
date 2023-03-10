#!/bin/sh

#docker buildx use multiarch
docker buildx build --platform linux/amd64 --tag k0d3r1s/php-fpm:unstable-supervisor --tag k0d3r1s/php-fpm:8.3.0-dev-supervisor --push --compress --no-cache -f Dockerfile.super . || exit
#docker buildx use default

docker pull k0d3r1s/php-fpm:unstable-supervisor
docker pull k0d3r1s/php-fpm:8.3.0-dev-supervisor
