FROM    k0d3r1s/alpine:unstable-curl as builder

USER    root

ARG     version

ENV     PHPIZE_DEPS autoconf dpkg-dev dpkg file g++ gcc libc-dev make pkgconf re2c
ENV     PHP_INI_DIR /usr/local/etc/php
ENV     PHP_CFLAGS "-fstack-protector-strong -fpic -fpie -O2 -ftree-vectorize -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -march=native"
ENV     PHP_CPPFLAGS "$PHP_CFLAGS"
ENV     PHP_LDFLAGS "-Wl,-O2 -pie"
ENV     PHP_VERSION 8.3.0-dev

COPY    ping.sh /usr/local/bin/php-fpm-ping
COPY    ./src/ /usr/src/php

ENTRYPOINT ["docker-php-entrypoint"]

STOPSIGNAL SIGQUIT

EXPOSE 9000

WORKDIR /home/vairogs

RUN     \
        set -eux \
&&      apk upgrade --no-cache --update --no-progress -X http://dl-cdn.alpinelinux.org/alpine/edge/testing \
&&      apk add --update --no-cache --no-progress --upgrade -X http://dl-cdn.alpinelinux.org/alpine/edge/testing alpine-sdk argon2-dev autoconf bison bzip2 bzip2-dev readline-dev readline \ 
        coreutils curl-dev dpkg dpkg-dev fcgi file freetype freetype-dev g++ gcc git gmp gmp-dev gnu-libiconv gnu-libiconv-dev gnupg hiredis hiredis-dev icu icu-dev \
        icu-libs imagemagick imagemagick-dev libc-dev libedit-dev libev libev-dev libevent libevent-dev libgomp libjpeg-turbo libjpeg-turbo-dev liblzf liblzf-dev rabbitmq-c \
        libpng libpng-dev librdkafka librdkafka-dev libsodium-dev libtool libuv libuv-dev libwebp libwebp-dev libx11 libxau libxdmcp libxml2 libxml2-dev libxpm rabbitmq-c-dev \
        libxpm-dev libzip libzip-dev linux-headers lz4 lz4-dev lz4-libs make oniguruma-dev openssh-client openssl openssl-dev pcre pcre-dev php82-dev php82-pear libidn2-dev \
        pinentry pkgconf postgresql-dev postgresql-libs re2c sqlite-dev tar tidyhtml tidyhtml-dev wget xz zip zstd-dev zstd-libs libpsl-dev rtmpdump-dev libgsasl-dev \
        sqlite sqlite-libs sqlite-dev openssl1.1-compat \
&&      wget -O /home/vairogs/installer https://getcomposer.org/installer \
&&      wget -O /usr/local/bin/wait-for-it https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh \
&&      wget -O /usr/local/bin/pickle.phar https://github.com/FriendsOfPHP/pickle/releases/latest/download/pickle.phar \
&&      wget -O /usr/local/bin/docker-php-entrypoint https://raw.githubusercontent.com/docker-library/php/master/8.2/alpine3.17/fpm/docker-php-entrypoint \
&&      wget -O /usr/local/bin/docker-php-ext-enable https://raw.githubusercontent.com/docker-library/php/master/8.2/alpine3.17/fpm/docker-php-ext-enable \
&&      wget -O /usr/local/bin/docker-php-source https://raw.githubusercontent.com/simpletoimplement/docker-library-php/master/8/alpine/fpm/docker-php-source \
&&      wget -O /usr/local/bin/php-fpm-healthcheck https://raw.githubusercontent.com/renatomefi/php-fpm-healthcheck/master/php-fpm-healthcheck \
&&      wget -O /usr/local/bin/docker-php-ext-install https://raw.githubusercontent.com/docker-library/php/master/8.2/alpine3.17/fpm/docker-php-ext-install \
&&      wget -O /usr/local/bin/docker-php-ext-configure https://raw.githubusercontent.com/docker-library/php/master/8.2/alpine3.17/fpm/docker-php-ext-configure \
&&      chmod -R 777 /usr/local/bin \
&&      chmod 777 /home/vairogs/installer \
&&      mkdir --parents "$PHP_INI_DIR/conf.d" \
&&      [ ! -d /var/www/html ]; \
        mkdir --parents /var/www/html \
&&      chown vairogs:vairogs /var/www/html \
&&      chmod 777 -R /var/www/html \
&&      export \
            CFLAGS="$PHP_CFLAGS" \
            CPPFLAGS="$PHP_CPPFLAGS" \
            LDFLAGS="$PHP_LDFLAGS" \
&&      cd /usr/src/php \
&&      gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
&&      ./buildconf --force \
&&      ./configure \
            --build="$gnuArch" \
            --with-config-file-path="$PHP_INI_DIR" \
            --with-config-file-scan-dir="$PHP_INI_DIR/conf.d" \
            --disable-cgi \
            --disable-ftp \
            --disable-short-tags \
            --disable-mysqlnd \
            --disable-phpdbg \
            --enable-bcmath \
            --enable-calendar \
            --enable-exif \
            --enable-fpm \
            --enable-huge-code-pages \
            --enable-intl \
            --enable-mbstring \
            --enable-opcache \
            --enable-option-checking=fatal \
            --enable-pcntl \
            --enable-sysvsem \
            --enable-sysvshm \
            --enable-sysvmsg \
            --enable-shmop \
            --enable-soap \
            --enable-sockets \
            --with-bz2 \
            --with-curl \
            --with-fpm-group=vairogs \
            --with-fpm-user=vairogs \
            --with-gmp \
            --with-libedit \
            --with-mhash \
            --with-openssl \
            --with-password-argon2 \
            --with-pear \
            --with-pic \
            --with-pdo-sqlite=/usr \
            --with-readline \
            --with-sodium=shared \
    		--with-sqlite3=/usr \
            --with-tidy \
            --with-zlib \
&&      make -j "$(expr $(nproc) / 3)" \
&&      find -type f -name '*.a' -delete \
&&      make install \
&&      find /usr/local/bin /usr/local/sbin -type f -perm +0111 -exec strip --strip-all '{}' + || true \
&&      make clean \
&&      mkdir --parents "$PHP_INI_DIR" \
&&      cp -v php.ini-* "$PHP_INI_DIR/" \
&&      cd / \
&&      runDeps="$( \
            scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
            | tr ',' '\n' \
            | sort -u \
            | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
        )" \
&&      apk add --no-cache $runDeps \
&&      pecl update-channels \
&&      rm -rf \
            /tmp/pear \
            ~/.pearrc \
&&      php --version \
&&      mkdir --parents "$PHP_INI_DIR/conf.d" \
&&      chmod -R 777 /usr/local/bin \
&&      docker-php-ext-enable sodium \
&&      mkdir --parents --mode=777 --verbose /run/php-fpm \
&&      mkdir --parents /var/www/html/config \
&&      touch /run/php-fpm/.keep_dir \
&&      cat /home/vairogs/installer | php -- --install-dir=/usr/local/bin --filename=composer \
&&      composer self-update --snapshot \
&&      chmod +x /usr/local/bin/pickle.phar \
&&      export CFLAGS="$PHP_CFLAGS" CPPFLAGS="$PHP_CPPFLAGS" LDFLAGS="$PHP_LDFLAGS" \
&&      docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/ --with-webp=/usr/include/ \
&&      pickle.phar install -n inotify \
&&      pickle.phar install -n msgpack \
&&      pickle.phar install -n lzf \
&&      docker-php-ext-install pdo_pgsql pgsql gd zip \
&&      docker-php-ext-enable gd msgpack inotify opcache pdo_pgsql pgsql zip lzf \
&&      mkdir --parents /home/vairogs/extensions \
&&      cd /home/vairogs/extensions \
&&      git clone --single-branch https://github.com/krakjoe/apcu.git \
&&      ( \
            cd  apcu \
            &&  phpize \
            &&  ./configure \
            &&  make -j "$(expr $(nproc) / 3)" \
            &&  make install \
            &&  cd .. || exit \
        ) \
&&      docker-php-ext-enable apcu \
&&      git clone --single-branch https://github.com/igbinary/igbinary.git \
# &&      git clone --single-branch https://github.com/simpletoimplement/igbinary-igbinary.git \
&&      ( \
            cd  igbinary \
        #     cd  igbinary-igbinary \
            &&  phpize \
            &&  ./configure CFLAGS="-O2 -g" --enable-igbinary \
            &&  make -j "$(expr $(nproc) / 3)" \
            &&  make install \
            &&  cd .. || exit \
        ) \
&&      docker-php-ext-enable igbinary \
&&      git clone --single-branch https://github.com/phpredis/phpredis.git \
&&      ( \
            cd  phpredis \
            &&  phpize \
            # &&  ./configure --enable-redis-zstd --enable-redis-msgpack --enable-redis-lzf --with-liblzf --enable-redis-lz4 --with-liblz4 \
            &&  ./configure --enable-redis-igbinary --enable-redis-zstd --enable-redis-msgpack --enable-redis-lzf --with-liblzf --enable-redis-lz4 --with-liblz4 \
            &&  make -j "$(expr $(nproc) / 3)" \
            &&  make install \
            &&  cd .. || exit \
        ) \
&&      docker-php-ext-enable redis \
&&      git clone --single-branch https://github.com/simpletoimplement/phpiredis.git \
&&      ( \
            cd  phpiredis \
            &&  phpize \
            &&  ./configure --enable-phpiredis \
            &&  make -j "$(expr $(nproc) / 3)" \
            &&  make install \
            &&  cd .. || exit \
        ) \
&&      docker-php-ext-enable phpiredis \
# &&      git clone --branch develop --single-branch https://github.com/Imagick/imagick.git \
&&      git clone --branch develop --single-branch https://github.com/simpletoimplement/imagick.git \
&&      ( \
            cd  imagick \
            &&  phpize \
            &&  ./configure \
            &&  make -j "$(expr $(nproc) / 3)" \
            &&  make install \
            &&  cd .. || exit \
        ) \
&&      docker-php-ext-enable imagick \
# &&      git clone --single-branch https://github.com/arnaud-lb/php-rdkafka.git \
# &&      ( \
#             cd  php-rdkafka \
#             &&  phpize \
#             &&  ./configure \
#             &&  make all -j "$(expr $(nproc) / 3)" \
#             &&  make install \
#             &&  cd .. || exit \
#         ) \
# &&      docker-php-ext-enable rdkafka \
&&      git clone --single-branch https://github.com/bwoebi/php-uv.git \
&&      ( \
            cd  php-uv \
            &&  phpize \
            &&  ./configure \
            &&  make -j "$(expr $(nproc) / 3)" \
            &&  make install \
            &&  cd .. || exit \
        ) \
&&      docker-php-ext-enable uv \
&&      git clone --single-branch https://bitbucket.org/osmanov/pecl-event.git \
&&      ( \
            cd  pecl-event \
            &&  phpize \
            &&  ./configure --with-event-core --with-event-extra --with-event-openssl \
            &&  make -j "$(expr $(nproc) / 3)" \
            &&  make install \
            &&  cd .. || exit \
        ) \
&&      docker-php-ext-enable event \
&&      git clone --single-branch https://bitbucket.org/osmanov/pecl-ev.git \
&&      ( \
            cd  pecl-ev \
            &&  phpize \
            &&  ./configure --enable-ev \
            &&  make -j "$(expr $(nproc) / 3)" \
            &&  make install \
            &&  cd .. || exit \
        ) \
&&      docker-php-ext-enable ev \
&&      git clone --single-branch https://github.com/rosmanov/pecl-eio.git \
&&      ( \
            cd  pecl-eio \
            &&  phpize \
            &&  ./configure --with-eio --enable-eio-sockets \
            &&  make -j "$(expr $(nproc) / 3)" \
            &&  make install \
            &&  cd .. || exit \
        ) \
&&      docker-php-ext-enable eio \
# &&      git clone --single-branch https://github.com/php-amqp/php-amqp.git \
# &&      ( \
#             cd  php-amqp \
#             &&  phpize \
#             &&  ./configure \
#             &&  make -j "$(expr $(nproc) / 3)" \
#             &&  make install \
#             &&  cd .. || exit \
#         ) \
# &&      docker-php-ext-enable amqp \
&&      curl -L "https://builds.r2.relay.so/dev/relay-dev-php8.3-alpine-x86-64.tar.gz" | tar xz -C /tmp \
&&      cp "/tmp/relay-dev-php8.3-alpine-x86-64/relay-pkg.so" $(php-config --extension-dir)/relay.so \
&&      sed -i "s/00000000-0000-0000-0000-000000000000/$(cat /proc/sys/kernel/random/uuid)/" $(php-config --extension-dir)/relay.so \
&&      chmod 755 $(php-config --extension-dir)/relay.so \
&&      touch /var/www/html/config/preload.php \
&&      apk del --purge --no-cache alpine-sdk argon2-dev autoconf bison bzip2-dev coreutils curl-dev dpkg dpkg-dev file freetype-dev g++ gcc gmp-dev rabbitmq-c-dev sqlite-dev \
        gnu-libiconv-dev gnupg hiredis-dev icu-dev imagemagick-dev libc-dev libedit-dev libev-dev libevent-dev libjpeg-turbo-dev liblzf-dev libpng-dev libidn2-dev readline-dev \
        librdkafka-dev libsodium-dev liburing-dev libuv-dev libwebp-dev libx11-dev libxau-dev libxdmcp-dev libxml2-dev libxpm-dev libzip-dev linux-headers libgsasl-dev \
        lz4-dev oniguruma-dev openssh* openssl-dev pcre-dev php82-dev php82-pear pkgconf postgresql-dev re2c sqlite-dev tidyhtml-dev xz zstd-dev libpsl-dev rtmpdump-dev \
&&      rm -rf \
            ~/.pearrc \
            /home/vairogs/installer \
            /home/vairogs/extensions \
            /tmp/* \
            /usr/local/bin/docker-php-ext-configure \
            /usr/local/bin/docker-php-ext-enable \
            /usr/local/bin/docker-php-ext-install \
            /usr/local/bin/docker-php-source \
            /usr/local/bin/pickle.phar \
            /usr/local/bin/phpdbg \
            /usr/local/etc/php-fpm.conf \
            /usr/local/etc/php-fpm.d/* \
            /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini \
            /usr/local/etc/php/php.ini \
            /usr/local/php/man/* \
            /usr/src/php \
            /var/cache/* \
            /usr/local/etc/php/php.ini-development \
            /usr/local/etc/php/php.ini-production \
&&      mkdir --parents /var/lib/php/sessions \
&&      chown -R vairogs:vairogs /var/lib/php/sessions \
&&      mkdir --parents /var/lib/php/opcache \
&&      chown -R vairogs:vairogs /var/lib/php/opcache

COPY    php-fpm.conf /usr/local/etc/php-fpm.conf
COPY    www.conf /usr/local/etc/php-fpm.d/www.conf
COPY    php.ini-development /usr/local/etc/php/php.ini
COPY    10-opcache.ini /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini
COPY    60-relay.ini /usr/local/etc/php/conf.d/docker-php-ext-relay.ini

RUN     \
        set -eux \
&&      chmod 644 /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini \
&&      echo zlib.output_compression = 4096 >> /usr/local/etc/php/conf.d/docker-php-ext-zlib.ini \
&&      echo zlib.output_compression_level = 9 >> /usr/local/etc/php/conf.d/docker-php-ext-zlib.ini \
&&      git config --global --add safe.directory "*"

FROM    scratch

COPY    --from=builder / / 

ENV     PHP_INI_DIR /usr/local/etc/php
ENV     PHP_VERSION 8.3.0-dev
ENV     container=docker
LABEL   maintainer="support+docker@vairogs.com"

SHELL   ["/bin/bash", "-o", "pipefail", "-c"]

STOPSIGNAL SIGQUIT

EXPOSE 9000

WORKDIR /var/www/html

USER    vairogs

CMD     ["sh", "-c", "php-fpm && /bin/bash"]

# grpc
