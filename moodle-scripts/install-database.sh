#!/usr/bin/env bash

required=(MOODLE_PASSWORD MOODLE_EMAIL MOODLE_SITE_NAME)
missing=()

for env_name in "${required[@]}"
do
  if [[ -z ${!env_name} ]]; then
    missing+=($env_name)
  fi
done

if (( ${#missing[@]} )); then
  message="Cannot install Moodle database because the following environment variables are not set:"
  for env_name in "${missing[@]}"
  do
    message+=" $env_name"
  done
  echo $message >&2
  exit 1
fi

cd /var/www/moodle || exit 1

echo "Installing Moodle database..."

sudo -u moodle /usr/local/bin/php admin/cli/install_database.php \
--lang=${MOODLE_LANGUAGE:-en} \
--adminuser="${MOODLE_USERNAME:-admin}" \
--adminpass="$MOODLE_PASSWORD" \
--adminemail="$MOODLE_EMAIL" \
--agree-license \
--fullname="$MOODLE_SITE_NAME" \
--shortname="${MOODLE_SITE_SHORTNAME:-$MOODLE_SITE_NAME}"

result=$?

if [ $result -eq 0 ]; then
  echo "Moodle database successfully installed."
else
  echo "Error installing Moodle database." >&2
  exit $result
fi
