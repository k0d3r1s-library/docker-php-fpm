#!/bin/sh

# docker build --tag k0d3r1s/php-fpm:unstable-testing --tag k0d3r1s/php-fpm:8.3.0-dev-testing --compress --no-cache -f Dockerfile.xdebug . || exit

rm -rf src
cp -r source src
rm -rf src/.git src/.github

#docker buildx use multiarch
docker buildx build --platform linux/amd64 --tag k0d3r1s/php-fpm:unstable-testing --tag k0d3r1s/php-fpm:8.3.0-dev-testing --push --compress --no-cache -f Dockerfile.xdebug . || exit
#docker buildx use default

rm -rf src

docker pull k0d3r1s/php-fpm:unstable-testing
docker pull k0d3r1s/php-fpm:8.3.0-dev-testing
