FROM php:7.4-apache-buster

ENV LD_LIBRARY_PATH /usr/local/instantclient
ENV APACHE_PROXY 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16

# Fix the original permissions of /tmp, the PHP default upload tmp dir.
RUN chmod 777 /tmp && chmod +t /tmp

# enable mod_remoteip for using behind a reverse proxy
COPY remoteip.conf /etc/apache2/conf-available/
RUN a2enmod rewrite remoteip ;\
    a2enconf remoteip;\
    sed -ri -e 's!%h!%a!g' /etc/apache2/apache2.conf

# change document root to /var/www/moodle
RUN sed -ri -e 's!/var/www/html!/var/www/moodle!g' /etc/apache2/sites-available/*.conf

# Setup the required extensions.
ARG DEBIAN_FRONTEND=noninteractive

# Build packages will be added during the build, but will be removed at the end.
ARG BUILD_PACKAGES="gettext gnupg libcurl4-openssl-dev libfreetype6-dev libicu-dev libjpeg62-turbo-dev \
  libldap2-dev libmariadbclient-dev libmemcached-dev libpng-dev libpq-dev libxml2-dev libxslt-dev \
  unixodbc-dev"

# Packages for Postgres.
ARG PACKAGES_POSTGRES="libpq5"

# Packages for MariaDB and MySQL.
ARG PACKAGES_MYMARIA="libmariadb3"

# Packages for other Moodle runtime dependenices.
ARG PACKAGES_RUNTIME="ghostscript libaio1 libcurl4 libgss3 libicu63 libmcrypt-dev libxml2 libxslt1.1 \
  libzip-dev locales sassc unixodbc unzip zip aspell aspell-en aspell-fr clamav"

# Packages for Memcached.
ARG PACKAGES_MEMCACHED="libmemcached11 libmemcachedutil2"

# Packages for LDAP.
ARG PACKAGES_LDAP="libldap-2.4-2"

# Other packages
ARG PACKAGES_OTHER="apt-transport-https git sudo"

# Install packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    $PACKAGES_OTHER \
    $BUILD_PACKAGES \
    $PACKAGES_POSTGRES \
    $PACKAGES_MYMARIA \
    $PACKAGES_RUNTIME \
    $PACKAGES_MEMCACHED \
    $PACKAGES_LDAP

# Generate locales
COPY locale.gen /etc/
RUN locale-gen

# Install php extensions
RUN docker-php-ext-install -j$(nproc) exif intl mysqli opcache pgsql soap xsl xmlrpc zip

# GD
RUN docker-php-ext-configure gd --with-freetype --with-jpeg && docker-php-ext-install -j$(nproc) gd

# LDAP
RUN docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
    && docker-php-ext-install -j$(nproc) ldap \
    && echo "" >> /etc/ldap/ldap.conf \
    && echo "# Disable verifying the certs of LDAPS servers." >> /etc/ldap/ldap.conf \
    && echo -e "TLS_REQCERT\tnever" >> /etc/ldap/ldap.conf \
    && echo "" >> /etc/ldap/ldap.conf

# Memcached, MongoDB, Redis, APCu, igbinary.
RUN pecl install memcached \
    && pecl install mongodb \
    && pecl install redis-4.3.0 \
    && pecl install apcu \
    && pecl install igbinary \
    && docker-php-ext-enable memcached mongodb redis apcu igbinary

# Enable APC CLI
RUN echo 'apc.enable_cli = On' >> /usr/local/etc/php/conf.d/docker-php-ext-apcu.ini

# Clean up
RUN pecl clear-cache \
    && apt-get remove --purge -y $BUILD_PACKAGES \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy PHP config
COPY php.ini $PHP_INI_DIR/

# Run freshclam once so that there are definitions ready before first auto update
RUN freshclam

# Environment variables used by scripts
ENV MOODLE_VERSION 3.9
ENV SCRIPTS_DIR=/usr/local/moodle-scripts

# create a directory for the scripts used by the container
RUN mkdir -p $SCRIPTS_DIR
WORKDIR $SCRIPTS_DIR
COPY moodle-scripts/*.sh ./
RUN chmod +x *.sh

ENTRYPOINT ["./dockerstart.sh"]
