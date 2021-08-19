#!/usr/bin/env bash

/moodle-scripts/set-timezone.sh
/moodle-scripts/assign-user-id.sh
/moodle-scripts/update-moodle.sh
/moodle-scripts/set-apache-servername.sh
/moodle-scripts/cron-jobs.sh

exec apache2-foreground
