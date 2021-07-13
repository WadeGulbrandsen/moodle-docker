#!/usr/bin/env bash

PUID=${PUID:-1000}
PGID=${PGID:-1000}

echo "Setting uid and gid"

groupmod -o -g "$PGID" moodle
usermod -o -u "$PUID" moodle

echo "Moodle uid: $(id -u moodle)"
echo "Moodle gid: $(id -g moodle)"
