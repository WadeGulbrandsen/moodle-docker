#!/usr/bin/env bash

cd /var/www/moodle || exit 1

if [[ ! -d "/data/plugins" ]]; then
  echo "Creating /data/plugins directory"
  mkdir -p /data/plugins
fi

SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

plugins=$(git ls-files . --exclude-standard --others --directory)

if [[ -z $plugins ]]; then
  echo "No plugins to backup"
fi

for plugin in $plugins
do
  echo "Backing up: $plugin"
  rsync -a --relative --del "$plugin" /data/plugins/
done

IFS=$SAVEIFS

cd /data/plugins || exit 1

shopt -s nullglob
shopt -s dotglob

for dir in */*/
do
  if [[ "$plugins" != *"$dir"* ]]; then
    echo "Removing unused: $dir"
    rm -rf "$dir"
  fi
done

for dir in */
do
  contents=("$dir"/*)
  if (( ! ${#contents[*]} )); then
    echo "Removing empty: $dir"
    rm -rf "$dir"
  fi
done
