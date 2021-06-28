#!/usr/bin/env bash

set -e

echo "Installing apt dependencies"

# Build packages will be added during the build, but will be removed at the end.
BUILD_PACKAGES="gettext gnupg libcurl4-openssl-dev libfreetype6-dev libicu-dev libjpeg62-turbo-dev \
  libldap2-dev libmariadbclient-dev libmemcached-dev libpng-dev libpq-dev libxml2-dev libxslt-dev \
  unixodbc-dev"

# Packages for Postgres.
PACKAGES_POSTGRES="libpq5"

# Packages for MariaDB and MySQL.
PACKAGES_MYMARIA="libmariadb3"

# Packages for other Moodle runtime dependenices.
PACKAGES_RUNTIME="ghostscript libaio1 libcurl4 libgss3 libicu63 libmcrypt-dev libxml2 libxslt1.1 \
  libzip-dev locales sassc unixodbc unzip zip aspell aspell-en aspell-fr clamav"

# Packages for Memcached.
PACKAGES_MEMCACHED="libmemcached11 libmemcachedutil2"

# Packages for LDAP.
PACKAGES_LDAP="libldap-2.4-2"

apt-get update
apt-get install -y --no-install-recommends apt-transport-https wget git \
    $BUILD_PACKAGES \
    $PACKAGES_POSTGRES \
    $PACKAGES_MYMARIA \
    $PACKAGES_RUNTIME \
    $PACKAGES_MEMCACHED \
    $PACKAGES_LDAP

# Generate the locales configuration.
echo 'Generating locales..'
echo 'en.UTF-8 UTF-8' > /etc/locale.gen
echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen
echo 'en_CA.UTF-8 UTF-8' >> /etc/locale.gen
echo 'en_AU.UTF-8 UTF-8' >> /etc/locale.gen
echo 'fr_FR.UTF-8 UTF-8' >> /etc/locale.gen
echo 'fr_CA.UTF-8 UTF-8' >> /etc/locale.gen
locale-gen

echo "Installing php extensions"
docker-php-ext-install -j$(nproc) \
    exif \
    intl \
    mysqli \
    opcache \
    pgsql \
    soap \
    xsl \
    xmlrpc \
    zip

# GD.
docker-php-ext-configure gd --with-freetype --with-jpeg
docker-php-ext-install -j$(nproc) gd

# LDAP.
docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/
docker-php-ext-install -j$(nproc) ldap

# Allow untrusted certs for LDAPS
echo "" >> /etc/ldap/ldap.conf
echo "# Disable verifying the certs of LDAPS servers." >> /etc/ldap/ldap.conf
echo -e "TLS_REQCERT\tnever" >> /etc/ldap/ldap.conf
echo "" >> /etc/ldap/ldap.conf

# Memcached, MongoDB, Redis, APCu, igbinary.
pecl install memcached
pecl install mongodb
pecl install redis-4.3.0
pecl install apcu
pecl install igbinary
docker-php-ext-enable memcached mongodb redis apcu igbinary

echo 'apc.enable_cli = On' >> /usr/local/etc/php/conf.d/docker-php-ext-apcu.ini

# Keep our image size down..
pecl clear-cache
apt-get remove --purge -y $BUILD_PACKAGES
apt-get autoremove -y
apt-get clean
rm -rf /var/lib/apt/lists/*
