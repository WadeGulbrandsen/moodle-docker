#!/usr/bin/env bash

NL=$'\n'

/moodle-scripts/assign-user-id.sh

if [[ -n "$MOODLE_CRON" ]]; then
  echo "Setting Moodle cron job schedule to $MOODLE_CRON in /etc/cron.d/moodle"
  echo "$MOODLE_CRON moodle /usr/local/bin/php /var/www/moodle/admin/cli/cron.php >/dev/null" > /etc/cron.d/moodle
elif [ -f /etc/cron.d/moodle ]; then
  echo "Removing Moodle cron job from /etc/cron.d"
  rm -f /etc/cron.d/moodle
fi

if [[ -n "$CLAMAV_CRON" ]]; then
  echo "Updating ClamAV definitions..."
  freshclam --quiet
  echo "Setting ClamAV cron job schedule to $CLAMAV_CRON in /etc/cron.d/clamav"
  echo "$CLAMAV_CRON root freshclam --quiet >/dev/null" > /etc/cron.d/clamav
elif [ -f /etc/cron.d/clamav ]; then
  echo "Removing ClamAV cron job from /etc/cron.d"
  rm -f /etc/cron.d/clamav
fi

/moodle-scripts/update-moodle.sh
/moodle-scripts/set-apache-servername.sh

if [[ -n "$MOODLE_CRON" ]] || [[ -n "$CLAMAV_CRON" ]]; then
  service cron start
fi

exec apache2-foreground
