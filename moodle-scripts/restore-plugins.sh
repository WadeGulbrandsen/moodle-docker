#!/usr/bin/env bash

shopt -s nullglob

if [ -d "/data/plugins" ]; then
  cd /data/plugins || exit 1
  SAVEIFS=$IFS
  IFS=$(echo -en "\n\b")
  plugins=(*/*/)
  for plugin in "${plugins[@]}"
  do
    echo "Restoring: $plugin"
    rsync -a --relative "$plugin" /var/www/moodle
  done
  IFS=$SAVEIFS
fi
