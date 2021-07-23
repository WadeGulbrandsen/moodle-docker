#!/usr/bin/env bash

docker_output=">/proc/1/fd/1 2>/proc/1/fd/2"

if [[ -n "$MOODLE_CRON" ]]; then
  echo "Setting Moodle cron job schedule to $MOODLE_CRON in /etc/cron.d/moodle"
  echo "$MOODLE_CRON moodle /usr/local/bin/php /var/www/moodle/admin/cli/cron.php >/dev/null" > /etc/cron.d/moodle
elif [ -f /etc/cron.d/moodle ]; then
  echo "Removing Moodle cron job from /etc/cron.d"
  rm -f /etc/cron.d/moodle
fi

if [[ -n "$BACKUP_CRON" ]]; then
  echo "Setting Backup cron job schedule to $BACKUP_CRON in /etc/cron.d/backup-moodle"
  echo "$BACKUP_CRON root /moodle-scripts/backup-config.sh $docker_output" > /etc/cron.d/backup-moodle
  echo "$BACKUP_CRON root /moodle-scripts/backup-plugins.sh $docker_output" >> /etc/cron.d/backup-moodle
elif [ -f /etc/cron.d/backup-moodle ]; then
  echo "Removing Backup cron job from /etc/cron.d"
  rm -f /etc/cron.d/backup-moodle
fi

if [[ -n "$UPDATE_CRON" ]]; then
  echo "Setting Update cron job schedule to $UPDATE_CRON in /etc/cron.d/update-moodle"
  printenv | grep -E 'MOODLE_BRANCH|AUTO_UPGRADE|GIT_URL' > /etc/cron.d/update-moodle
  echo "$UPDATE_CRON root bash -l -c '/moodle-scripts/update-moodle.sh' $docker_output" >> /etc/cron.d/update-moodle
elif [ -f /etc/cron.d/update-moodle ]; then
  echo "Removing Update cron job from /etc/cron.d"
  rm -f /etc/cron.d/update-moodle
fi

if [[ -n "$RESTORE_CRON" ]]; then
  echo "Setting Restore cron job schedule to $RESTORE_CRON in /etc/cron.d/restore-plugins"
  echo "$RESTORE_CRON root /moodle-scripts/restore-plugins.sh $docker_output" > /etc/cron.d/restore-plugins
elif [ -f /etc/cron.d/restore-plugins ]; then
  echo "Removing Restore cron job from /etc/cron.d"
  rm -f /etc/cron.d/restore-plugins
fi

shopt -s nullglob

contents=(/etc/cron.d/*)
if (( ${#contents[*]} )); then
  service cron start
fi
