# Moodle

Docker Image for Moodle. Based on [Moodle HQ's Docker image](https://github.com/moodlehq/moodle-php-apache).

## Features

* Moodle installed with git to make updates easier
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
  * Sets ownership on Moodle directories to www-data
  * Auto updates to the latest build in `MOODLE_BRANCH`
  * Sets the Apache ServerName from the wwwroot in config.php
* Cron jobs
  * Update ClamAV once a day
  * Run `/usr/local/bin/php /var/www/moodle/admin/cli/cron.php` as www-data every minute
    Can be disabled by setting the NO_MOODLE_CRON environment variable. If disabled you should set up some other method
    for running Moodle's tasks.
* Directories set up to file caches so they don't have to live in the moodledata directory.
  This is useful if you have moodledata on a network drive.
  The following exist in the container.
  
  Directory            | Line to add to config.php                    | Cluster safe
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
`NO_MOODLE_CRON` | No       | *BLANK*                                   | Set this to disable the built in cron job for Moodle. Useful in a cluster where you only want a single node running tasks.

## Volume

All data that should persist should be mounted at `/data`

If no bind or volume is given a default volume will be mounted for you

Item         | Type      | Description
------------ | --------- | -----------
`config.php` | file      | Moodle configuration file
`moodledata` | directory | moodledata directory `/var/www/moodledata` symlinks here
`plugins`    | directory | Put your plugins in here and they will be copied into the container

### config.php file

The config.php isn't created automatically. You can create it in one of 3 ways.
1. Create the file by hand and place it in the data volume (Only do this if you already set up Moodle before)
2. Start the container and access it in your browser and follow the Moodle WebUI to set up
3. Start the container and run
   `docker exec -it <container> sudo -u www-data /usr/local/bin/php /var/www/moodle/admin/cli/install.php`

After doing method 2 or 3 copy the config.php file to the data volume by running
`docker exec <container> cp /var/www/moodle/config.php /data/`

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