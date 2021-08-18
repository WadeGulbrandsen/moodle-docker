#!/usr/bin/env bash

if [[ -z "$MOODLE_DATABASE_PASSWORD" ]]; then
  echo "Cannot create config.php because MOODLE_DATABASE_PASSWORD is not set." >&2
  exit 1
elif [ -f "/var/www/moodle/config.php" ]; then
  echo "/var/www/moodle/config.php already exists." >&2
  exit 1
else
  echo "Creating /var/www/moodle/config.php"
fi

MOODLE_DATABASE_TYPE=${MOODLE_DATABASE_TYPE:-mysqli}
MOODLE_WWW_ROOT=${MOODLE_WWW_ROOT:-http://moodle.example.com}

echo "<?php  // Moodle configuration file

unset(\$CFG);
global \$CFG;
\$CFG = new stdClass();

\$CFG->dbtype    = '$MOODLE_DATABASE_TYPE';
\$CFG->dblibrary = 'native';
\$CFG->dbhost    = '${MOODLE_DATABASE_HOST:-db}';
\$CFG->dbname    = '${MOODLE_DATABASE_NAME:-moodledb}';
\$CFG->dbuser    = '${MOODLE_DATABASE_USER:-moodledbuser}';
\$CFG->dbpass    = '$MOODLE_DATABASE_PASSWORD';
\$CFG->prefix    = 'mdl_';
\$CFG->dboptions = array (
  'dbpersist' => 0,
  'dbport' => '$MOODLE_DATABASE_PORT_NUMBER',
  'dbsocket' => ''," > /var/www/moodle/config.php

if [[ "mysqli mariadb auroramysql" =~ "$MOODLE_DATABASE_TYPE" ]]; then
  echo "  'dbcollation' => '${MYSQL_DATABASE_COLLATION:-utf8mb4_unicode_ci}'," >> /var/www/moodle/config.php
fi

echo ");

\$CFG->wwwroot   = '$MOODLE_WWW_ROOT';
\$CFG->dataroot  = '/var/www/moodledata';
\$CFG->admin     = 'admin';
" >> /var/www/moodle/config.php

if [[ "$MOODLE_WWW_ROOT" == "https://"* ]]; then
  echo "\$CFG->sslproxy  = true;
" >> /var/www/moodle/config.php
fi

if [[ -n "$MOODLE_LOCAL_CACHE_DIR" ]]; then
  echo "\$CFG->localcachedir = '$MOODLE_LOCAL_CACHE_DIR';" >> /var/www/moodle/config.php
fi

if [[ -n "$MOODLE_CACHE_DIR" ]]; then
  echo "\$CFG->cachedir      = '$MOODLE_CACHE_DIR';" >> /var/www/moodle/config.php
fi

if [[ -n "$MOODEL_TEMP_DIR" ]]; then
  echo "\$CFG->tempdir       = '$MOODEL_TEMP_DIR';" >> /var/www/moodle/config.php
fi

echo "
\$CFG->directorypermissions = 02775;

require_once(__DIR__ . '/lib/setup.php');

// There is no php closing tag in this file,
// it is intentional because it prevents trailing whitespace problems!" >> /var/www/moodle/config.php

chown moodle:moodle /var/www/moodle/config.php