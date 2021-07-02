#!/usr/bin/env bash

echo "Updating ClamAV definitions..."
freshclam --quiet

/moodle-scripts/update-moodle.sh
/moodle-scripts/set-apache-servername.sh

exec apache2-foreground
