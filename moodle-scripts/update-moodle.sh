#!/usr/bin/env bash

if [ ! -d "/data/moodledata" ]; then
  echo "Creating /data/moodledata directory"
  mkdir -p /data/moodledata
fi

if [ -f "/data/config.php" ]; then
  # Copying instead of linking because this gets loaded on every request so can slow Moodle down if this is on slow file system (nfs, efs, etc)
  echo "Copying config.php into /var/www/moodle/"
  cp -f /data/config.php /var/www/moodle/
fi

if [ -d "/data/plugins" ] && [ -n "$(ls -A /data/plugins)" ]; then
  echo "Copying plugins into /var/www/moodle/"
  cp -ru /data/plugins/* /var/www/moodle/
fi

echo "Setting file ownership..."
chown -R www-data:www-data /var/www/moodle /data/moodledata /moodle

cd /var/www/moodle || exit 1

version=$(echo "$MOODLE_BRANCH" | cut -d'_' -f 2)

if [[ $(git branch -a) != *"$MOODLE_BRANCH"* ]]; then
  echo "ERROR: $MOODLE_BRANCH is not a valid git branch"
  exit 1
fi

echo "Updating to $MOODLE_BRANCH"
echo "Checking current branch"
current_branch=$(git rev-parse --abbrev-ref HEAD)

if [[ "" == "$current_branch" ]]; then
  echo "ERROR: Could not verify the current branch"
  exit 1
else
  echo "Current branch is $current_branch"
fi

current_version=$(echo "$current_branch" | cut -d'_' -f 2)

if (( version >= current_version )); then
  if (( version == current_version )); then
    echo "Current branch is the desired branch. Pulling git updates."
    git pull
  else
    echo "Changing from git branch $current_branch to $MOODLE_BRANCH"
    git branch --track "$MOODLE_BRANCH" "origin/$MOODLE_BRANCH"
    git checkout "$MOODLE_BRANCH"
  fi
  chown -R www-data:www-data /var/www/moodle
  sudo -u www-data /usr/local/bin/php admin/cli/maintenance.php --enable
  sudo -u www-data /usr/local/bin/php admin/cli/upgrade.php --non-interactive
  sudo -u www-data /usr/local/bin/php admin/cli/purge_caches.php
  sudo -u www-data /usr/local/bin/php admin/cli/maintenance.php --disable
else
  echo "ERROR: The desired branch is older than the current branch"
  exit 1
fi
