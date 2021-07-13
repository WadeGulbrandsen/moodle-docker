#!/usr/bin/env bash

if [ ! -d "/var/www/moodle" ]; then
  echo "Installing Moodle from git..."
  cd /var/www || exit 1
  # Using the github copy of Moodle to allow blobless clone
  git clone git://github.com/moodle/moodle.git --branch "$MOODLE_BRANCH" --filter=blob:none
  cd moodle || exit 1
fi

if [ ! -d "/data/moodledata" ]; then
  echo "Creating /data/moodledata directory"
  mkdir -p /data/moodledata
fi

if [ -f "/data/config.php" ]; then
  # Copying instead of linking because this gets loaded on every request so can slow Moodle down if this is on slow file system (nfs, efs, etc)
  echo "Copying config.php into /var/www/moodle/"
  cp -fp /data/config.php /var/www/moodle/
fi

/moodle-scripts/restore-plugins.sh

echo "Setting file ownership..."
chown -R moodle:moodle /var/www/moodle /data /moodle

cd /var/www/moodle || exit 1

echo "Fetching updates from git"
git fetch

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
    git checkout --track "origin/$MOODLE_BRANCH"
  fi
  chown -R moodle:moodle /var/www/moodle
  if [ -f config.php ]; then
    database_status=$(sudo -u moodle /usr/local/bin/php admin/cli/check_database_schema.php)
    echo "Moodle Database status: $database_status"
    if [[ "Database structure is ok." == "$database_status" ]]; then
      upgrade_status=$(sudo -u moodle /usr/local/bin/php admin/cli/checks.php --filter=Upgrade)
      echo "Moodle Upgrade status: $upgrade_status"
      if [[ "OK: All 'status' checks OK" != "$upgrade_status" ]]; then
        sudo -u moodle /usr/local/bin/php admin/cli/maintenance.php --enable
        sudo -u moodle /usr/local/bin/php admin/cli/upgrade.php --non-interactive
        sudo -u moodle /usr/local/bin/php admin/cli/purge_caches.php
        sudo -u moodle /usr/local/bin/php admin/cli/maintenance.php --disable
      fi
    fi
  fi
else
  echo "ERROR: The desired branch is older than the current branch"
  exit 1
fi
