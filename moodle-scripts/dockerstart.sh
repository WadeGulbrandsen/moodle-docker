#!/usr/bin/env bash

/moodle-scripts/assign-user-id.sh

if [[ -n "$MOODLE_CRON" ]]; then
  echo "Setting Moodle cron job schedule to $MOODLE_CRON in /etc/cron.d/moodle"
  echo "$MOODLE_CRON moodle /usr/local/bin/php /var/www/moodle/admin/cli/cron.php >/dev/null" > /etc/cron.d/moodle
elif [ -f /etc/cron.d/moodle ]; then
  echo "Removing Moodle cron job from /etc/cron.d"
  rm -f /etc/cron.d/moodle
fi

/moodle-scripts/update-moodle.sh
/moodle-scripts/set-apache-servername.sh

if [[ -n "$MOODLE_CRON" ]]; then
  service cron start
fi

exec apache2-foreground
