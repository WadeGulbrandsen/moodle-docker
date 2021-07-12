#!/usr/bin/env bash

cd /var/www/moodle || exit 1

if [ -d "/data/plugins" ]; then
  echo "Removing old plugins from /data/plugins"
  rm -rf /data/plugins/*
else
  echo "Creating /data/plugins directory"
  mkdir -p /data/plugins
fi

SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

files=$(git ls-files . --exclude-standard --others)

if [[ -z $files ]]; then
  echo "No plugins to backup"
else
  echo "Backing up plugins"
fi

for file in $files
do
  cp --parents -f "$file" /data/plugins/
done

cd /data/plugins || exit 1

plugins=$(ls -d -- */*)

for plugin in $plugins
do
  echo "Plugin: $plugin"
done

IFS=$SAVEIFS
