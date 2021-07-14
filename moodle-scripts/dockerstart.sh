#!/usr/bin/env bash

/moodle-scripts/assign-user-id.sh

if [[ -z "$NO_MOODLE_CRON" ]]; then
  echo "Copying Moodle cron job to /etc/cron.d"
  cp /moodle-scripts/cron/moodle /etc/cron.d/
else
  echo "Removing Moodle cron job from /etc/cron.d"
  rm -f /etc/cron.d/moodle
fi

echo "Updating ClamAV definitions..."
freshclam --quiet

/moodle-scripts/update-moodle.sh
/moodle-scripts/set-apache-servername.sh

service cron start

exec apache2-foreground
