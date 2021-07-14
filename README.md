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
  * `ClamAV` to use with the Antivirus plugin
  * `LDAP` to use with the LDAP Authentication
  * `memcached`, `redis`, and `mongodb` libraries to connect to cache servers
  * `aspell` with dictionaries for English and French
* On start or restart the following will be done
  * Update ClamAV definitions
  * Copies plugins in /data/plugins into the container (uses the -u option to only overwrite older files)
  * Sets ownership on Moodle directories to `moodle`
  * Auto updates to the latest build in the `MOODLE_BRANCH` environment variable
  * Sets the Apache ServerName from `wwwroot` in `config.php`
* Cron jobs
  * Update ClamAV once a day
  * Run `/usr/local/bin/php /var/www/moodle/admin/cli/cron.php` as `moodle` every minute
    Can be disabled by setting the NO_MOODLE_CRON environment variable. If disabled you should set up some other method
    for running Moodle scheduled tasks.
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

Tag             | MOODLE_BRANCH     | PHP Version
--------------- | ----------------- | -----------
`latest` `3.11` | MOODLE_311_STABLE | 7.4
`3.11`          | MOODLE_311_STABLE | 7.4
`3.10`          | MOODLE_310_STABLE | 7.4
`lts` `3.9`     | MOODLE_39_STABLE  | 7.4
`3.8`           | MOODLE_38_STABLE  | 7.4

## Environment Variables
Variable         | Required | Default                                   | Description
---------------- | -------- | ----------------------------------------- | -----------
`MOODLE_BRANCH`  | No       | The MOODLE_BRANCH from the table above    | The git branch that will be checked out. This can be set to upgrade Moodle to a newer version. Make sure that the new version works with the PHP Version 
`APACHE_PROXY`   | No       | `10.0.0.0/8 172.16.0.0/12 192.168.0.0/16` | Space separated CIDR address(s) of proxy servers in front of Moodle. Defaults to the standard private subnets.
`NO_MOODLE_CRON` | No       | *NOT SET*                                 | Set this to disable the built in cron job for Moodle. Useful in a cluster where you only want a single node running tasks.
`PUID`           | No       | `1000`                                    | User ID for the `moodle` user
`GUID`           | No       | `1000`                                    | Group ID for the `moodle` user

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
    volumes:
      - /path/to/data:/data
    ports:
      - 80:80
    depends_on:
      - db
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
`backup-config.sh` Copies /var/www/moodle/config.php to /data/config.php
```shell
docker exec your_moodle_container backup-config.sh
```
`backup-plugins.sh` Copies plugins that are not built into core Moodle to /data/plugins and removes any plugins in
/data/plugins that are no longer used in the running Moodle.
```shell
docker exec your_moodle_container backup-plugins.sh
```

#### Update running Moodle
`restore-plugins.sh` Copies all the plugins in /data/plugins to /var/www/moodle
```shell
docker exec your_moodle_container restore-plugins.sh
```
`update-moodle.sh` Updates Moodle from the /data directory
* Copies /data/config.php into /var/www/moodle
* runs `restore-plugins`
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