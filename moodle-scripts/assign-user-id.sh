#!/usr/bin/env bash

PUID=${PUID:-1000}
PGID=${PGID:-1000}

echo "Setting Moodle uid and gid"

groupmod -o -g "$PGID" moodle &> /dev/null
usermod -o -u "$PUID" moodle &> /dev/null

echo "Moodle uid: $(id -u moodle)"
echo "Moodle gid: $(id -g moodle)"
