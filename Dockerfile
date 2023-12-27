FROM php:8.2-apache-bookworm

RUN apt-get update && apt-get install -y ca-certificates curl gnupg apt-transport-https

RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
RUN echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list

ENV COMPOSER_ALLOW_SUPERUSER 1
ENV COMPOSER_HOME /home/.composer
RUN mkdir -p /home/.composer
RUN  apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y \
    # Tools
    vim git cron wget zip unzip \
    # other
    dma  \
    build-essential \
    mariadb-client \
    openssl \
    supervisor \
    nodejs \
    ghostscript \
    sudo && rm -rf /var/lib/apt/lists/*

# auto install dependencies and remove libs after installing ext: https://github.com/mlocati/docker-php-extension-installer
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

RUN install-php-extensions \
    opcache \
    intl \
    pdo_mysql \
    zip \
    bcmath \
    @composer


RUN apt-get purge -y --auto-remove
RUN a2enmod rewrite

COPY docker/001-zephyr.conf /etc/apache2/sites-enabled/001-zephyr.conf
RUN touch /var/www/.bash_history && chmod 777 /var/www/.bash_history
# Run from unprivileged port 8080 only
RUN sed -e 's/Listen 80/Listen 8080/g' -i /etc/apache2/ports.conf

COPY ./docker/dma.conf /etc/dma/dma.conf
COPY docker/zephyr.ini /usr/local/etc/php/conf.d/zephyr.ini

ARG UNAME=www-data
ARG UGROUP=www-data
ARG UID=1000
ARG GID=1000
RUN usermod  --uid $UID $UNAME
RUN groupmod --gid $GID $UGROUP

USER www-data

WORKDIR /var/www/html
CMD ["docker-php-entrypoint", "apache2-foreground"]
