#!/usr/bin/env bash

if [[ -z "$TZ" ]]; then
  echo "TZ is not set"
  exit 1
elif [[ -e "/usr/share/zoneinfo/$TZ" ]]; then
  echo "Setting timezone to $TZ"
  ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime
  echo $TZ > /etc/timezone
else
  echo "$TZ is not a valid timezone"
  exit 1
fi
