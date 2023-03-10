#!/bin/bash

set -e

FCGI_STATUS_PATH=/ping php-fpm-healthcheck
echo $?
