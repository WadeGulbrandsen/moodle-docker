#!/usr/bin/env bash
cd /var/www/moodle || exit 1

version=$(echo "$MOODLE_VERSION" | tr -d .)
git_branch="MOODLE_${version}_STABLE"

if [[ $(git branch -a) != *"$git_branch"* ]]; then
  echo "ERROR: $git_branch is not a valid git branch"
  exit 1
fi

echo "Updating to $git_branch"
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
  sudo -u www-data /usr/local/bin/php admin/cli/maintenance.php --enable

  if (( version == current_version )); then
    echo "Current branch is the desired branch"
    git pull
  else
    if [ -f config.php ]; then
      echo "Backing up config file"
      cp -f config.php ../"config-$current_version.php"
    fi
    echo "Changing from git branch $current_branch to $git_branch"
    git branch --track "$git_branch" "origin/$git_branch"
    git checkout "$git_branch"
  fi

  sudo -u www-data /usr/local/bin/php admin/cli/upgrade.php --non-interactive
  sudo -u www-data /usr/local/bin/php admin/cli/purge_caches.php
  sudo -u www-data /usr/local/bin/php admin/cli/maintenance.php --disable
else
  echo "ERROR: The desired branch is older than the current branch"
  exit 1
fi
