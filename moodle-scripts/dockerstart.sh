#!/usr/bin/env bash

if [ ! -d "/var/www/moodledata" ]; then
  echo "Creating moodledata directory"
  mkdir /var/www/moodledata
fi

if [ -d "/var/www/moodle" ]; then
  "$SCRIPTS_DIR"/update-moodle.sh
else
  "$SCRIPTS_DIR"/install-moodle.sh
fi

echo "Setting file permissions on /var/www/moodle and /var/www/moodledata"
chown -R www-data:www-data /var/www/moodle*

exec apache2-foreground
