#!/usr/bin/env bash

if [ -f /var/www/moodle/config.php ]; then
  echo "Backing up config.php"
  cp -up /var/www/moodle/config.php /data/
fi
