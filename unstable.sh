#!/bin/sh

cd ./source || exit
git reset --hard
git pull
VERSION=`git rev-parse --short HEAD`

cd .. || exit

rm -rf src
cp -r source src
rm -rf src/.git src/.github

#old=`cat latest`
#hub-tool tag rm k0d3r1s/php-fpm:$old -f
echo -n $VERSION > latest
docker pull k0d3r1s/alpine:unstable-curl

# docker build --tag k0d3r1s/php-fpm:${VERSION} --tag k0d3r1s/php-fpm:unstable --tag k0d3r1s/php-fpm:8.3.0-dev --compress --no-cache -f Dockerfile.unstable . || exit

#docker buildx use multiarch
docker buildx build --platform linux/amd64 --tag k0d3r1s/php-fpm:unstable --tag k0d3r1s/php-fpm:8.3.0-dev --push --compress --no-cache -f Dockerfile . || exit
#docker buildx use default

rm -rf src

#docker pull k0d3r1s/php-fpm:${VERSION}
docker pull k0d3r1s/php-fpm:unstable
docker pull k0d3r1s/php-fpm:8.3.0-dev
