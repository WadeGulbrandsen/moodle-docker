#!/usr/bin/env bash

moodle_re="CFG->wwwroot\s+=\s+'https?:\/\/(\S+)';"
apache_re="^\s*(#?)ServerName (\S+)$"

moodle_file="/var/www/moodle/config.php"
apache_file="/etc/apache2/apache2.conf"

if [ -f "$moodle_file" ]; then
  if [[ $(cat "$moodle_file") =~ $moodle_re ]]; then
    domain="${BASH_REMATCH[1]}"
    new="ServerName $domain"
    if [[ $(grep -E "$apache_re" "$apache_file") =~ $apache_re ]]; then
      crunch="${BASH_REMATCH[1]}"
      current="${BASH_REMATCH[2]}"
      if [[ "$domain" != "$current" ]] || [[ "$crunch" == "#" ]]; then
        old="$crunch""ServerName $current"
        echo "Replacing '$old' with '$new' in $apache_file"
        sed -ri -e "s!$old!$new!" "$apache_file"
      fi
    else
      echo "Adding '$new' to $apache_file"
      { echo ""; echo "# ServerName"; echo "$new"; } >> "$apache_file"
    fi
  fi
fi
