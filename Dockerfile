FROM wodby/php-actions-alpine:dev
MAINTAINER Wodby <hello@wodby.com>

RUN export TWIG_VER="1.24.0" && \
    export WALTER_VER="1.3.0" && \

    echo '@testing http://nl.alpinelinux.org/alpine/edge/testing' >> /etc/apk/repositories && \

    # Install common packages
    apk add --update \
        git \
        nano \
        grep \
        sed \
        curl \
        wget \
        tar \
        gzip \
        pcre \
        perl \
        openssh \
        patch \
        patchutils \
        diffutils \
        msmtp \
        inotify-tools \
        && \

    # Install PHP specific packages
    apk add --update \
        mariadb-client \
        imap \
        redis \
        imagemagick \
        && \

    # Install PHP extensions
    apk add --update \
        php \
        php-cli \
        php-fpm \
        php-opcache \
        php-xml \
        php-ctype \
        php-ftp \
        php-gd \
        php-json \
        php-posix \
        php-curl \
        php-dom \
        php-pdo \
        php-pdo_mysql \
        php-sockets \
        php-zlib \
        php-mcrypt \
        php-mysqli \
        php-bz2 \
        php-pear \
        php-phar \
        php-openssl \
        php-posix \
        php-redis@testing \
        php-zip \
        php-calendar \
        php-iconv \
        php-imap \
        php-memcache \
        php-xdebug@testing \
        php-imagick@testing \
        && \

    # Configure php.ini
    sed -i "s/^expose_php.*/expose_php = Off/" /etc/php/php.ini && \
    sed -i "s/^;date.timezone.*/date.timezone = UTC/" /etc/php/php.ini && \
    sed -i "s/^memory_limit.*/memory_limit = -1/" /etc/php/php.ini && \
    sed -i "s/^max_execution_time.*/max_execution_time = 300/" /etc/php/php.ini && \
    sed -i "s/^post_max_size.*/post_max_size = 512M/" /etc/php/php.ini && \
    sed -i "s/^upload_max_filesize.*/upload_max_filesize = 512M/" /etc/php/php.ini && \
    echo "extension_dir = \"/usr/lib/php/modules\"" | tee -a /etc/php/php.ini && \
    echo "error_log = \"/var/log/php/error.log\"" | tee -a /etc/php/php.ini && \

    # Configure php log dir
    mkdir /var/log/php && \
    touch /var/log/php/error.log && \
    touch /var/log/php/fpm-error.log && \
    touch /var/log/php/fpm-slow.log && \
    chown -R wodby:wodby /var/log/php && \

    # Install Twig template engine
    apk add --update build-base php-dev php-pear autoconf libtool pcre-dev && \
    wget -qO- https://github.com/twigphp/Twig/archive/v${TWIG_VER}.tar.gz | tar xz -C /tmp/ && \
    cd /tmp/Twig-${TWIG_VER}/ext/twig && \
    phpize && ./configure && make && make install && \
    echo 'extension=twig.so' > /etc/php/conf.d/twig.ini && \

    # Install PHP extensions through Pecl
    sed -ie 's/-n//g' `which pecl` && \
    pecl install uploadprogress && \
    echo 'extension=uploadprogress.so' > /etc/php/conf.d/uploadprogress.ini && \

    # Purge dev APK packages
    apk del --purge *-dev build-base autoconf libtool && \

    # Cleanup after phpizing
    cd / && rm -rf /usr/include/php /usr/lib/php/build /usr/lib/php/20090626/*.a && \

    # Remove redis binaries and config
    rm -f /usr/bin/redis-* && /etc/redis.conf && \

    # Replace sendmail by msmtp
    ln -sf /usr/bin/msmtp /usr/sbin/sendmail && \

    # Define Git global config
    git config --global user.name "Administrator" && \
    git config --global user.email "admin@wodby.com" && \
    git config --global push.default current && \

    # Install composer, drush and wp-cli
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
    git clone https://github.com/drush-ops/drush.git /usr/local/src/drush && \
    cd /usr/local/src/drush && \
    ln -sf /usr/local/src/drush/drush /usr/bin/drush && \
    composer install && rm -rf ./.git && \
    composer create-project wp-cli/wp-cli /usr/local/src/wp-cli --no-dev && \
    ln -sf /usr/local/src/wp-cli/bin/wp /usr/bin/wp && \

    # Install Walter tool
    wget -qO- https://github.com/walter-cd/walter/releases/download/v${WALTER_VER}/walter_${WALTER_VER}_linux_amd64.tar.gz | tar xz -C /tmp/ && \
    mkdir /opt/wodby/bin && \
    cp /tmp/walter_linux_amd64/walter /opt/wodby/bin && \

    # Fix permissions
    chmod 755 /root && \

    # Final cleanup
    rm -rf /var/cache/apk/* /tmp/* /usr/share/man

COPY rootfs /
