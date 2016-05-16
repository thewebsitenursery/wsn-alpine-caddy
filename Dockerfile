FROM wodby/nginx-alpine:edge
MAINTAINER Wodby <hello@wodby.com>

RUN export PHP_ACTIONS_VER="v1.0.18" && \
    export UPLOADPROGRESS_VER="0.1.0" && \
    export XDEBUG_VER="2.4.0" && \
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
        && \

    # Add PHP actions
    cd /tmp && \
    git clone https://github.com/Wodby/php-actions-alpine.git && \
    cd php-actions-alpine && \
    git checkout $PHP_ACTIONS_VER && \
    rsync -av rootfs/ / && \

    # Install PHP specific packages
    apk add --update \
        mariadb-client \
        imap \
        redis \
        imagemagick \
        && \

    # Install PHP extensions
    apk add --update \
        php7@testing \
        php7-fpm@testing \
        php7-opcache@testing \
        php7-xml@testing \
        php7-ctype@testing \
        php7-ftp@testing \
        php7-gd@testing \
        php7-json@testing \
        php7-posix@testing \
        php7-curl@testing \
        php7-dom@testing \
        php7-pdo@testing \
        php7-pdo_mysql@testing \
        php7-sockets@testing \
        php7-zlib@testing \
        php7-mcrypt@testing \
        php7-mysqli@testing \
        php7-bz2@testing \
        php7-phar@testing \
        php7-openssl@testing \
        php7-posix@testing \
        php7-zip@testing \
        php7-calendar@testing \
        php7-iconv@testing \
        php7-imap@testing \
        php7-soap@testing \
        php7-dev@testing \
        php7-pear@testing \
        php7-redis@testing \
        && \

    # Create symlinks PHP -> PHP7
    ln -sf /etc/php7 /etc/php && \
    ln -sf /var/log/php7 /var/log/php && \
    ln -sf /usr/lib/php7 /usr/lib/php && \
    ln -sf /usr/bin/php7 /usr/bin/php && \
    ln -sf /usr/bin/phpize7 /usr/bin/phpize && \
    ln -sf /usr/bin/php-config7 /usr/bin/php-config && \

    # Create symlink PHP-FPM
    ln -sf /usr/sbin/php-fmp7 /usr/bin/php-fpm && \

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
    touch /var/log/php/error.log && \
    touch /var/log/php/fpm-error.log && \
    touch /var/log/php/fpm-slow.log && \
    chown -R wodby:wodby /var/log/php && \

    # Install uploadprogess extension
    apk add --update build-base autoconf libtool pcre-dev && \
    wget -qO- https://s3.amazonaws.com/wodby-releases/uploadprogress/v${UPLOADPROGRESS_VER}/php7-uploadprogress.tar.gz | tar xz -C /tmp/ && \
    cd /tmp/uploadprogress-${UPLOADPROGRESS_VER} && \
    phpize && ./configure && make && make install && \
    echo 'extension=uploadprogress.so' > /etc/php/conf.d/uploadprogress.ini && \

    # Install xdebug extension
    wget -qO- wget http://xdebug.org/files/xdebug-{XDEBUG_VER}.tgz | tar xz -C /tmp/ && \
    cd /tmp/xdebug-${XDEBUG_VER} && \
    phpize && ./configure && make && make install && \

    # Purge dev APK packages
    apk del --purge *-dev build-base autoconf libtool && \

    # Cleanup after phpizing
    cd / && rm -rf /usr/include/php /usr/lib/php/build /usr/lib/php/20090626/*.a && \

    # Remove redis binaries and config
    rm -f /usr/bin/redis-* /etc/redis.conf && \

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
    wget -qO- https://s3.amazonaws.com/wodby-releases/walter-cd/v${WALTER_VER}/walter.tar.gz | tar xz -C /tmp/ && \
    mkdir -p /opt/wodby/bin && \
    cp /tmp/walter_linux_amd64/walter /opt/wodby/bin && \

    # Fix permissions
    chmod 755 /root && \

    # Final cleanup
    rm -rf /var/cache/apk/* /tmp/* /usr/share/man

COPY rootfs /
