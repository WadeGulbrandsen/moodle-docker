# Moodle

Docker Image for Moodle.

Image is on [Docker Hub](https://hub.docker.com/r/wadegulbrandsen/moodle-docker)

Source is on [GitHub](https://github.com/WadeGulbrandsen/moodle-docker)

Based on [Moodle HQ's Docker image](https://github.com/moodlehq/moodle-php-apache)

## Features

* Moodle installed with git to make updates easier
* Runs Apache as a user and group named `moodle` that can have their uid and gid set by environment variables 
* Works with `PostgreSQL`, `MySQL`, `MariaDB`, `AWS Aurora MySQL`, and `Microsoft SQL` databases
  
  ***Moodle 3.9 or higher is needed for Aurora***
* Supports English (US, AUS, CA) and French (FR, CA)
* Has the following extras installed
  * `LDAP` to use with the LDAP Authentication
  * `memcached`, `redis`, and `mongodb` libraries to connect to cache servers
  * `aspell` with dictionaries for English and French
* On start or restart the following will be done
  * Copies plugins in /data/plugins into the container (uses the -u option to only overwrite older files)
  * Sets ownership on Moodle directories to `moodle`
  * Optionally auto updates to the latest build in the `MOODLE_BRANCH` environment variable
  * Sets the Apache ServerName from `wwwroot` in `config.php`
* Cron jobs
  The jobs can use any schedule desired by setting the appropriate environment variables
  * `MOODLE_CRON` Runs `/usr/local/bin/php /var/www/moodle/admin/cli/cron.php` as `moodle` every minute.
    Can be disabled by clearing the `MOODLE_CRON` environment variable. If disabled you should set up some other method
    for running Moodle scheduled tasks.
  * `BACKUP_CRON` Runs the [`backup-config.sh`](#backup-config) and [`backup-plugins.sh`](#backup-plugins) scripts.
  Useful if you still want to use the Moodle webUI to install and update plugins. If you have a cluster only one node
  should use the backup job. The rest should use either the update or restore job.
  * `PLUGINS_CRON` Runs the [`backup-plugins.sh`](#backup-plugins) script.
    Same as `BACKUP_CRON` but doesn't backup config.php.
    Ideal if using environment variables instead of a config.php file.
  * `UPDATE_CRON` Runs the [`update-moodle.sh`](#update-moodle) script.
  Combine with `AUTO_UPGRADE` if you want the running Moodle to be updated when the contents of /data
  change. Only one node in a cluster should run this so that multiple nodes don't try to updata Moodle at the same time.
  * `RESTORE_CRON` Runs the [`restore-plugins.sh`](#restore-plugins) script. Use this if you want new plugins added to
  /data added to the running Moodle but you want to run the updates on your own.
    
  **Only one of `BACKUP_CRON`, `UPDATE_CRON` or `RESTORE_CRON` should be set on a container.**
* Directories set up to file caches so they don't have to live in the moodledata directory.
  This is useful if you have moodledata on a network drive.
  The following exist in the container.
  
  Directory            | Line to add to config.php                     | Cluster safe
  -------------------- | --------------------------------------------- | ------------
  `/moodle/localcache` | `$CFG->localcachedir = '/moodle/localcache';` | Yes
  `/moodle/cache`      | `$CFG->cachedir      = '/moodle/cache';`      | **NO**
  `/moodle/temp`       | `$CFG->tempdir       = '/moodle/temp';`       | **NO**

  **Only the localcache should be used if you have a cluster of Moodle servers.**

## Ports
Port 80 tcp is the only port needed

## Tags

`latest` follows the latest Moodle release

`lts` follows the current Long Term Support Moodle release

Tag            | MOODLE_BRANCH     | PHP Version
-------------- |-------------------| -----------
`latest` `4.0` | MOODLE_400_STABLE | 7.4
`3.11`         | MOODLE_311_STABLE | 7.4
`lts` `3.9`    | MOODLE_39_STABLE  | 7.4

## Environment Variables
Variable           | Default                                   | Description
------------------ | ----------------------------------------- | -----------
`GIT_URL`          | `https://github.com/moodle/moodle.git`    | The git repository to get Moodle from.
`MOODLE_BRANCH`    | The MOODLE_BRANCH from the table above    | The git branch that will be checked out. This can be set to upgrade Moodle to a newer version. Make sure that the new version works with the PHP Version 
`APACHE_PROXY`     | `10.0.0.0/8 172.16.0.0/12 192.168.0.0/16` | Space separated CIDR address(s) of proxy servers in front of Moodle. Defaults to the standard private subnets.
`AUTO_UPGRADE`     | *NOT SET*                                 | Set this to to enable automatic Moodle upgrades. When set if an update is pending the container will put Moodle in maintenance mode, run the upgrade script, purge caches, and take Moodle out of maintenance mode. Without this set you will need to do the upgrade in the webUI.
`PUID`             | `1000`                                    | User ID for the `moodle` user
`PGID`             | `1000`                                    | Group ID for the `moodle` user
`MOODLE_CRON`      | `* * * * *`                               | Runs the Moodle cron script every minute. Unset this to disable the built in cron job for Moodle. Useful in a cluster where you only want a single node running tasks.
`BACKUP_CRON`      | *NOT SET*                                 | Runs the `backup-config.sh` and `backup-plugins.sh` scripts to backup running moodle to /data
`PLUGINS_CRON`     | *NOT SET*                                 | Runs the `backup-plugins.sh` script to only backup the plugins.
`UPDATE_CRON`      | *NOT SET*                                 | Runs scripts to update the running moodle from /data
`RESTORE_CRON`     | *NOT SET*                                 | Copies plugins from /data into the running moodle
`TZ`               | `America/Toronto`                         | The timezone for the container. This will be the server timezone for Moodle on new installs.

For the environment variables ending in **_CRON** the format is the same as in cron.
See the [cron documentation](https://man7.org/linux/man-pages/man5/crontab.5.html) on the format.

The following can be used to create a config.php file. It will only be created the first time the container is run.
If config.php already exists in /data/ these settings will be ignored. To create the file `MOODLE_DATABASE_PASSWORD` is
required to be set.

Variable                      | Default                     | Description
----------------------------- | --------------------------- | -----------
`MOODLE_DATABASE_TYPE`        | `mysqli`                    | The type of database to use. Valid values are `pgsql`, `mysqli`, `mariadb`, `sqlsrv`, and `auroramysql`
`MOODLE_DATABASE_HOST`        | `db`                        | The hostname or IP address for the database server.
`MOODLE_DATABASE_PORT_NUMBER` | *NOT SET*                   | The port used by the database. Only needed if not using the default port for the database.
`MOODLE_DATABASE_NAME`        | `moodledb`                  | The name of the Moodle database.
`MOODLE_DATABASE_USER`        | `moodledbuser`              | The username to access the Moodle database.
`MOODLE_DATABASE_PASSWORD`    | *NOT SET*                   | The password for the Moodle database. **(REQUIRED)**
`MYSQL_DATABASE_COLLATION`    | `utf8mb4_unicode_ci`        | The collation used by `mysqli`, `mariadb`, and `auroramysql` databases. Ignored for other types.
`MOODLE_WWW_ROOT`             | `http://moodle.example.com` | The URL to users access Moodle from. If the URL starts with https:// then ssslproxy will be set to true.
`MOODLE_LOCAL_CACHE_DIR`      | `/moodle/localcache`        | The location for the local cache.
`MOODLE_CACHE_DIR`            | *NOT SET*                   | The location for the shared cache. Can use `/moodle/cache` for non-clustered Moodle.
`MOODLE_TEMP_DIR`             | *NOT SET*                   | The location for temp files. Can use `/moodle/temp` for non-clustered Moodle.
`MOODLE_EXTRA_MEMORY_LIMIT`   | *NOT SET*                   | Moodle will increase PHP's memory limit up to this before doing intensive operations. The value for the settings should be a valid PHP memory value. e.g. 512M, 1G 
`BBB_SERVER_URL`              | *NOT SET*                   | The URL for your BigBlueButton e.g. http://test-install.blindsidenetworks.com/bigbluebutton/ setting in config.php hides this in the web UI
`BBB_SHARED_SECRET`           | *NOT SET*                   | The security salt for your BigBlueButton. Setting in config.php hides this from the web UI

For a new Moodle that hasn't been installed yet the following can be used to do the initial Moodle setup.
These settings are ignored if the database has already been initialized. 

Variable                | Default   | Description
----------------------- | --------- | -----------
`MOODLE_SKIP_BOOTSTRAP` | *NOT SET* | If set the install will be skipped.
`MOODLE_LANGUAGE`       | `en`      | Default site language. Uses the 2 letter code for the language. en for English, fr for French, etc.
`MOODLE_USERNAME`       | `admin`   | Username for the moodle admin account.
`MOODLE_PASSWORD`       | *NOT SET* | Password for the moodle admin account. **(REQUIRED)**
`MOODLE_EMAIL`          | *NOT SET* | Email address for the moodle admin account. **(REQUIRED)**
`MOODLE_SITE_NAME`      | *NOT SET* | Full name of the site. **(REQUIRED)**
`MOODLE_SITE_SHORTNAME` | *NOT SET* | Short name for the site. Usually one word. If not set then the full name will be used.

## Volume

All data that should persist should be mounted at `/data`

If no bind or volume is given a default volume will be mounted for you

Item         | Type      | Description
------------ | --------- | -----------
`config.php` | file      | Moodle configuration file
`moodledata` | directory | moodledata directory `/var/www/moodledata` symlinks here
`plugins`    | directory | Put your plugins in here and they will be copied into the container

### config.php file

The config.php file isn't created automatically. You can create it in one of 3 ways.
1. Create the file by hand and place it in the data volume (Only do this if you already set up Moodle before)
2. Start the container and access it in your browser and follow the Moodle WebUI to set up
3. Start the container and run
   ```shell
   docker exec -it your_moodle_container \
   sudo -u moodle /usr/local/bin/php /var/www/moodle/admin/cli/install.php
   ```

After doing method 2 or 3 run the following commands to copy the config file to persistent storage
and update Apache's ServerName
```shell
docker exec your_moodle_container backup-config.sh
docker exec your_moodle_container set-apache-servername.sh
docker kill --signal USR1 your_moodle_container
```

If you have a reverse proxy or load balancer in front of the Moodle container you should add
`$CFG->reverseproxy = true;` if it is HTTP or `$CFG->sslproxy = true;` if it is HTTPS.

The `$CFG->webroot = 'http://www.example.com';` should match the URL that users access the proxy on.

Here's an example for a non-clustered Moodle behind an SSL proxy.

```php
<?php  // Moodle configuration file

unset($CFG);
global $CFG;
$CFG = new stdClass();

$CFG->dbtype    = 'pgsql';
$CFG->dblibrary = 'native';
$CFG->dbhost    = 'db';
$CFG->dbname    = 'moodle-db';
$CFG->dbuser    = 'moodle-user';
$CFG->dbpass    = 'secret-password';
$CFG->prefix    = 'mdl_';
$CFG->dboptions = array (
  'dbpersist' => 0,
  'dbport' => '',
  'dbsocket' => '',
);

$CFG->wwwroot   = 'https://moodle.example.com';
$CFG->dataroot  = '/var/www/moodledata';
$CFG->admin     = 'admin';

$CFG->sslproxy  = true;

$CFG->localcachedir = '/moodle/localcache';
$CFG->cachedir      = '/moodle/cache';
$CFG->tempdir       = '/moodle/temp';

$CFG->directorypermissions = 02775;

require_once(__DIR__ . '/lib/setup.php');

// There is no php closing tag in this file,
// it is intentional because it prevents trailing whitespace problems!

```

### plugins directory structure

Your plugins should be unzipped into the same folder structure as would be in the /var/www/moodle directory.

For example if you wanted to have the `Ad Hock Reports` plugin and the `Fordson` theme installed
you would need to extract them into the `report` and `theme` subdirectories respectively

`Ad Hock Reports` extracts to `customsql` and `Fordson` extracts to `fordson`

```text
Data Volume
|-- config.php
|-- moodledata
`-- plugins
    |-- report
    |   `-- customsql
    `-- theme
        `-- fordson
```

## Creating the container

To create the container docker-compose is recommended.

### Compose example

Create a file named `docker-compose.yml` with contents like:
```yaml
version: "2"
services:
  moodle:
    image: wadegulbrandsen/moodle-docker:lts
    environment:
      PUID: 1001
      PGID: 1001
      MOODLE_DATABASE_TYPE: 'pgsql'
      MOODLE_DATABASE_NAME: 'moodle-db'
      MOODLE_DATABASE_USER: 'moodle-user'
      MOODLE_DATABASE_PASSWORD: 'secret-password'
      MOODLE_WWW_ROOT: 'https://moodle.example.com'
      MOODLE_CACHE_DIR: '/moodle/cache'
      MOODLE_TEMP_DIR: '/moodle/temp'
      MOODLE_EXTRA_MEMORY_LIMIT: '512M'
    volumes:
      - /path/to/data:/data
    ports:
      - 80:80
    depends_on:
      - db
      - av
    restart: unless-stopped

  db:
    image: postgres:12
    environment:
      POSTGRES_PASSWORD: 'secret-password'
      POSTGRES_USER: 'moodle-user'
      POSTGRES_DB: 'moodle-db'
    volumes:
      - /path/to/database:/var/lib/postgresql/data
    restart: unless-stopped

  av:
    container_name: clamav
    image: tiredofit/clamav:latest
    environment:
      MAX_FILE_SIZE: 100M
      MAX_SCAN_SIZE: 100M
      PCRE_MAX_FILE_SIZE: 100M
      STREAM_MAX_LENGTH: 100M
    volumes:
      - /path/to/clamav/data:/data
      - /path/to/clamav/logs:/logs
    restart: unless-stopped
```

Then to start Moodle and its database run:

```shell
docker-compose up -d
```

### Starting with the docker run command

This is not recommended for normal operation but might be useful for testing.

If a volume for /data isn't specified a volume container will automatically be created.
```shell
docker run -d -p 80:80 --name your_moodle_container wadegulbrandsen/moodle-docker:3.9
```

To specify a volume or directory to be mounted add the -v option. Environment variables can be specified with -e options.
```shell
docker run -d -p 80:80 --name your_moodle_container -v /path/to/data:/data \
-e "PUID=1000" -e "PGID=1000" wadegulbrandsen/moodle-docker:lts
```

## Usage

For all example commands replace **your_moodle_container** with the name/ID of the Docker container running Moodle.

### Scripts

There are several scripts used for managing a running Moodle container.
The scripts are in the /moodle-scripts directory which is in the PATH variable so can be run from anywhere.

#### Backing up running config to persistent storage
<a name="backup-config"></a>`backup-config.sh` Copies /var/www/moodle/config.php to /data/config.php
```shell
docker exec your_moodle_container backup-config.sh
```
<a name="backup-plugins"></a>`backup-plugins.sh` Copies plugins that are not built into core Moodle to
/data/plugins. The script then removes any plugins in /data/plugins that the running Moodle no longer uses.
```shell
docker exec your_moodle_container backup-plugins.sh
```

#### Update running Moodle
<a name="restore-plugins"></a>`restore-plugins.sh` Copies all the plugins in /data/plugins to /var/www/moodle
```shell
docker exec your_moodle_container restore-plugins.sh
```
<a name="update-moodle"></a>`update-moodle.sh` Updates Moodle from the /data directory
* Copies /data/config.php into /var/www/moodle
* runs `restore-plugins.sh`
* Set ownership to all Moodle directories to `moodle`
* Updates the local copy of the Moodle git
* If the `MOODLE_BRANCH` environment variable is a valid newer branch of Moodle git with checkout that branch
* Check to the database connection and if Moodle needs to be updated:
  * Put Moodle into maintenance mode
  * Do the update
  * Purge caches
  * Take Moodle out of maintenance mode
```shell
docker exec your_moodle_container update-moodle.sh
```

#### Update Apache ServerName
`set-apache-servername.sh` Sets the Apache ServerName the domain in the `wwwroot` variable of /var/www/moodle/config.php
```shell
docker exec your_moodle_container set-apache-servername.sh
```

### Restart Apache
To restart Apache gracefully without restarting the container you can pass the USR1 signal to the container.
```shell
docker kill --signal USR1 your_moodle_container
```