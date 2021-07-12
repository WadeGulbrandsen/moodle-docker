FROM php:7.4-apache-buster
ENV APACHE_PROXY 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16

ADD root/ /

# Fix the original permissions of /tmp, the PHP default upload tmp dir.
RUN chmod 777 /tmp && chmod +t /tmp

# enable mod_remoteip for using behind a reverse proxy and change the document root
RUN a2enmod rewrite remoteip ;\
    a2enconf remoteip;\
    sed -ri -e 's!%h!%a!g' /etc/apache2/apache2.conf && \
    sed -ri -e 's!/var/www/html!/var/www/moodle!g' /etc/apache2/sites-available/*.conf && \
    rm -rf /var/www/html

# Setup the required extensions.
ARG DEBIAN_FRONTEND=noninteractive
RUN /tmp/setup/php-extensions.sh
ENV LD_LIBRARY_PATH /usr/local/instantclient

ENV MOODLE_BRANCH MOODLE_39_STABLE

# Set up the mount for data that should be persisted
RUN mkdir -p /data/plugins \
    && mkdir -p /data/moodledata \
    && ln -s /data/moodledata /var/www/moodledata \
    && chown -R www-data:www-data /var/www/moodledata
VOLUME /data

# Create directories used by Moodle
RUN mkdir -p /moodle/cache \
    && mkdir -p /moodle/localcache \
    && mkdir -p /moodle/temp \
    && mkdir -p /moodle-scripts

ADD moodle-scripts/ /moodle-scripts

# Set the working directory and make the scripts executeable
WORKDIR /moodle-scripts
RUN chmod +x *.sh

ENTRYPOINT ["./dockerstart.sh"]
