# Moodle

Docker Image for Moodle.

The version number in the tag refers to the version of PHP that is in the container.

The version of Moodle to be installed is specified with the **MOODLE_VERSION** environment variable.

## Environment Variables
Variable       | Required | Default | Description
-------------- | -------- | ------- | -----------
MOODLE_VERSION | No       | 3.9     | Moodle version. Just be the first 2 parts of the version separated by a dot. Don't include the 3rd part of the version. e.g. **3.9.7** should be entered as **3.9**.  3.9 is the current LTS release at time of writing.
APACHE_PROXY   | No       | 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16 | CIDR of address(s) of proxy server in front of Moodle. Defaults to the standard private subnets.

## Directories
The following directories are created automatically and the ownership set to www-data.

Directory           | Description
------------------- | -----------
/var/www/moodle     | Moodle install directory
/var/www/moodledata | Moodle data directory

## Features

* Sets permissions on Moodle directories on each start.
* Auto updates to the latest build in **MOODLE_VERSION** when the container starts or restarts.
  * If the current version is the same as **MOODLE_VERSION** `git pull` will be used
  * If the current version is less than **MOODLE_VERSION** the git branch will be changed to the new version 
  * If the current version is greater than **MOODLE_VERSION** the script will exit without doing anything
