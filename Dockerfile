FROM php:7.4-cli-buster

LABEL "com.github.actions.name"="Psalm"
LABEL "com.github.actions.description"="A static analysis tool for finding errors in PHP applications"
LABEL "com.github.actions.icon"="check"
LABEL "com.github.actions.color"="blue"

LABEL "repository"="http://github.com/psalm/psalm-github-actions"
LABEL "homepage"="http://github.com/actions"
LABEL "maintainer"="Matt Brown <github@muglug.com>"

# Code borrowed from mickaelandrieu/psalm-ga which in turn borrowed from phpqa/psalm

RUN apt-get update \
    && apt-get install -y --no-install-recommends git

# Install PHP extensions
RUN buildDeps="zlib1g-dev libicu-dev g++ libc-client-dev libkrb5-dev libxml2-dev libmcrypt-dev libgmp-dev libpng-dev libjpeg-dev libopenjp2-7-dev libzip-dev" \
    && apt-get update \
    && apt-get install -y --no-install-recommends $buildDeps libtiff5 gnupg2 libfontconfig runit \
    && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-install bcmath intl pdo_mysql imap soap opcache zip gmp gd calendar \
    && pecl install -o -f redis \
    && rm -rf /tmp/pear \
    && docker-php-ext-enable redis

COPY --from=composer:1.9 /usr/bin/composer /usr/bin/composer

RUN COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_HOME="/composer" \
    composer global config minimum-stability dev

# This line invalidates cache when master branch change
ADD https://github.com/vimeo/psalm/commits/master.atom /dev/null

RUN COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_HOME="/composer" \
    composer global require vimeo/psalm --prefer-dist --no-progress --dev

ENV PATH /composer/vendor/bin:${PATH}

# Satisfy Psalm's quest for a composer autoloader (with a symlink that disappears once a volume is mounted at /app)

RUN mkdir /app && ln -s /composer/vendor/ /app/vendor

# Add entrypoint script

COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Package container

WORKDIR "/app"
ENTRYPOINT ["/entrypoint.sh"]
