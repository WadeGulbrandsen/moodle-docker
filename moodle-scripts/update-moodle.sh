#!/usr/bin/env bash

NL=$'\n'
shopt -s nullglob
shopt -s dotglob

contents=(/var/www/moodle/*)
if (( ! ${#contents[*]} )); then
  echo "Installing Moodle from git..."
  cd /var/www || exit 1
  # do a shallow clone to make git faster and take less space
  git clone "$GIT_URL" --branch "$MOODLE_BRANCH" --depth 1 --quiet
  cd moodle || exit 1
fi

echo "Setting file ownership..."
chown -R moodle:moodle /var/www/moodle /data /moodle

if [ ! -d "/var/www/moodle/.git" ]; then
  echo "Moodle is not managed by git!" >&2
  exit 1
fi

if [ ! -d "/data/moodledata" ]; then
  echo "Creating /data/moodledata directory"
  mkdir -p /data/moodledata
fi

if [ -f "/data/config.php" ]; then
  # Copying instead of linking because this gets loaded on every request so can slow Moodle down if this is on slow file system (nfs, efs, etc)
  echo "Copying config.php into /var/www/moodle/"
  cp -fp /data/config.php /var/www/moodle/
else
  /moodle-scripts/create-config.sh
fi

/moodle-scripts/restore-plugins.sh

cd /var/www/moodle || exit 1

current_branch=$(git rev-parse --abbrev-ref HEAD)

if [[ "$MOODLE_BRANCH" == "$current_branch" ]]; then
  echo "Current branch is the desired branch. Pulling git updates."
  git fetch --depth=1 --quiet
  git reset --hard "origin/$current_branch"
  chown -R moodle:moodle /var/www/moodle
else
  current_version=$(echo "$current_branch" | cut -d'_' -f 2)
  new_version=$(echo "$MOODLE_BRANCH" | cut -d'_' -f 2)
  current_version="${current_version:0:1}.${current_version:1}"
  new_version="${new_version:0:1}.${new_version:1}"
  to_check="$current_version$NL$new_version"
  if [ "$to_check" == "$(sort -V <<< "$to_check")" ]; then
    if git ls-remote --exit-code --heads origin "$MOODLE_BRANCH" &> /dev/null; then
      echo "Upgrading from $current_branch to $MOODLE_BRANCH"
      if [[ $(git branch -a) != *"$MOODLE_BRANCH"* ]]; then
        git remote set-branches --add origin "$MOODLE_BRANCH"
      fi
      git fetch --depth=1
      if [[ $(git branch) != *"$MOODLE_BRANCH"* ]]; then
        git checkout --track "origin/$MOODLE_BRANCH" --quiet
      else
        git checkout -f -q "$MOODLE_BRANCH"
      fi
      chown -R moodle:moodle /var/www/moodle
    else
      echo "$MOODLE_BRANCH is not a valid branch" >&2
      exit 1
    fi
  else
    echo "Cannot upgrade to $MOODLE_BRANCH because it older than $current_branch" >&2
    exit 1
  fi
fi

# Clean up git
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

branch=$(git rev-parse --abbrev-ref HEAD)
local_branches=$(git branch)
remote_branches=$(git branch -r)

for lb in $local_branches
do
  trimmed=${lb:2}
  if [[ "$trimmed" != *"$branch"* ]]; then
    echo "Removing $trimmed from git"
    git branch -D "$trimmed"
  fi
done

for rb in $remote_branches
do
  trimmed=${rb:2}
  if [[ "$trimmed" != *"$branch"* ]]; then
    echo "Removing $trimmed from git"
    git branch -D -r "$trimmed"
  fi
done

git remote set-branches origin "$branch"

IFS=$SAVEIFS

sudo -u moodle /usr/local/bin/php admin/cli/upgrade.php --is-pending
result=$?
if [ $result -eq 2 ]; then
  if [[ -n "$AUTO_UPGRADE" ]]; then
    echo "Upgrading Moodle..."
    sudo -u moodle /usr/local/bin/php admin/cli/maintenance.php --enable
    sudo -u moodle /usr/local/bin/php admin/cli/upgrade.php --non-interactive
    sudo -u moodle /usr/local/bin/php admin/cli/purge_caches.php
    sudo -u moodle /usr/local/bin/php admin/cli/maintenance.php --disable
  else
    echo "Moodle upgrade is pending."
  fi
elif [ $result -eq 0 ]; then
  echo "Moodle is up to date."
else
  exit $result
fi
