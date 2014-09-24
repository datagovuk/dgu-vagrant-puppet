# Data.gov.uk To Go

This repo provides scripts to install a copy of data.gov.uk's website to your own server. Rebrand it and you have a fully-featured government open data portal.

## About

The UK Government has contributed Data.gov.uk To Go to Github to kick-start the use and development of common open data portal software, beyond the basic CKAN. UK wants to develop it in partnership with other providers of Open Data portals, through the usual Open Source / Github model of forking, pull requests, issues etc. that everyone is encouraged to contribute to.

## Overview

Here is an overview of the install process:

* Machine preparation - Vagrant VM or a fresh Ubuntu 12.04 machine
* CKAN source - download from Github
* Puppet provision of the main software packages (Apache, Postgres, SOLR etc) and set-up linux users
* CKAN database setup
* Drupal install
* Additional configuration

## Suggested system requirements

* 24GB RAM
* 8 cores
* 200GB disc

## 1. Machine preparation

### Option 1: Virtual Machine creation

Before creating the virtual machine, clone this repo to the host machine (its path will now be referred to as $THIS_REPO) and switch to the 'togo' branch:

    git clone git@github.com:datagovuk/dgu-vagrant-puppet
    cd dgu-vagrant-puppet
    git checkout togo

Use the script to clone all the CKAN source repos onto your host machine.

    cd $THIS_REPO/src
    ./git_clone_all.sh

Using Vagrant and Puppet, launch a fully provisioned Virtual Machine as described in this repo:

    cd $THIS_REPO
    vagrant up

Now a great deal should happen. Expect key stages:

* create the virtual machine (VM)
* boot the VM
* update some key Ubuntu packages like linux-headers
* mount the shared folders

At this point the shell text goes green and it does the "provision" which is:

* prepare to run librarian (install_puppet_dependancies.sh) - install git, update all Ubuntu packages, install ruby and librarian-puppet
* runs librarian-puppet - downloads all puppet modules that are required (listed in Puppetfile) and makes a copy of the CKAN puppet module.
* runs 'puppet apply' (blue output) - installs and configures CKAN and installs some dependencies of Drupal.

Provisioning will take a while, and you can ignore warnings that are listed in the section of this document titled 'Vagrant warnings'.

NB If there is an error and you want to restart the provisioning, from the host box you should do:

    vagrant provision

Now you can log into the new VM ("host" machine):

    vagrant ssh

The prompt will change to show your terminal is connected to the VM, you will be logged in as the vagrant user.
All further steps are from this ssh session on the VM after you have changed your user to 'co' with:

    sudo su co


### Option 2: Fresh machine preparation

Instead of using a virtual-machine it is perfectly fine alternative to use a non-virtual machine, freshly installed with Ubuntu 12.04. The Puppet scripts assume the name of the machine is 'ckan', so you need to login to it and rename it:

    sudo hostname ckan
    sudo vim /etc/hosts
    # ^ add "127.0.0.1  ckan" to hosts...

Puppet will assume the home user is called 'co', so create it with some particular options:

    sudo adduser co -u 510 -G sudo
    sudo su co

All further steps are to be carried out from the ssh session under the user 'co' on this target machine.

You need to install some dependencies:

    sudo apt-get install ruby1.9.3 rubygems git
    sudo ln -sf /usr/bin/ruby1.9.3 /etc/alternatives/ruby
    sudo gem install librarian-puppet -v 1.0.3

Clone this repo to the machine in /vagrant (to match the vagrant install) and switch to the 'togo' branch:

    mkdir /vagrant
    cd /vagrant
    git clone git@github.com:datagovuk/dgu-vagrant-puppet
    cd /vagrant/dgu-vagrant-puppet
    git checkout togo

Use the script to clone all the CKAN source repos.

     ln -s /vagrant/src /src
     cd /src
     ./git_clone_all.sh

Puppet is used to install and configure the main software packages (Apache, Postgres, SOLR etc) and setup linux users.

To provision an existing machine, install the puppet modules:

    sudo /vagrant/puppet/install_puppet_dependancies.sh

and then execute the site manifest now at /etc/puppet/:

    sudo puppet apply /vagrant/puppet/manifests/site.pp

Provisioning will take a while, and you can ignore warnings that are listed in the section of this document titled 'Vagrant warnings'.

To automatically activate your CKAN python virtual environment on log-in, it is recommended to add this line to your .bashrc:

    source ~/ckan/bin/activate && cd /src/ckan


## 2. Extra CKAN setup

(This extra setup will be usefully puppetized in the future)

Download NLTK Stopwords Corpus

   python -m nltk.downloader stopwords

### Harvesting

Harvester needs a backend. One option is RabbitMQ (installed by puppet).

The alternative backend is Redis. This requires extra CKAN configuration:
```
[app:celery]
BROKER_BACKEND = redis
BROKER_HOST = redis://localhost/1
CELERY_RESULT_BACKEND = redis
CELERY_SEND_EVENTS = True
REDIS_HOST = 127.0.0.1
REDIS_PORT = 6379
REDIS_DB = 0
REDIS_CONNECT_RETRY = True
```

You need to create the gather and fetch queues by running the consumers briefly:

    sudo -u www-data paster --plugin=ckanext-harvest harvester gather_consumer --config=../ckan/ckan.ini
    sudo -u www-data paster --plugin=ckanext-harvest harvester fetch_consumer --config=../ckan/ckan.ini

The queues should be left running, either in screen sessions, or preferably using supervisord.

Meanwhile you need the `harvester run` cron job to run every 10 minutes:

    */10 *  * * *   www-data  /home/co/ckan/bin/paster --plugin=ckanext-harvest harvester run --config=/var/ckan/ckan.ini


## 3. CKAN Database setup

**IMPORTANT** You must activate the CKAN virtual environment when working on the VM. Eg.:

    source ~/ckan/bin/activate

And make sure you run paster commands from the /vagrant/src/ckan directory.

#### Option 1: Use test data

    createdb -O dgu ckan --template template_postgis
    sudo -u www-data paster --plugin=ckanext-ga-report initdb --config=ckan.ini
    sudo -u www-data paster --plugin=ckanext-dgu create-test-data --config=ckan.ini
    sudo -u www-data paster search-index rebuild --config=ckan.ini

#### Option 2: Download an existing database

At data.gov.uk we download a database (using pg_dump and gzip) from another server like:

    mkdir -p /vagrant/db_backup
    rsync --progress co@co-prod3.dh.bytemark.co.uk:/var/ckan/backup/ckan.2014-09-18.pg_dump.gz /vagrant/db_backup/

Then load the dump in (ensure you are logged in as the co user):

    export CKAN_DUMP_FILE=`ls /vagrant/db_backup/ -t |head -n 1` && echo $CKAN_DUMP_FILE
    sudo apachectl stop
    dropdb ckan
    createdb -O dgu ckan --template template_postgis
    pv /vagrant/db_backup/$CKAN_DUMP_FILE | funzip \
      | PGPASSWORD=pass psql -h localhost -U dgu -d ckan
    sudo apachectl start
    sudo -u www-data paster db upgrade --config=ckan.ini
    sudo -u www-data paster search-index rebuild --config=ckan.ini

Note: expect the `pv` command to produce a number of non-fatal errors and warnings. At the start there are several pages of errors before it starts creating tables:

```
...
ERROR:  must be owner of type public.geometry or type bytea
ERROR:  must be owner of type public.geometry or type public.geography
ERROR:  must be owner of type public.geometry or type text
ERROR:  must be owner of type text or type public.geometry
SET
SET
SET
CREATE TABLE
ALTER TABLE
CREATE TABLE
ALTER TABLE
...
```

There are also a few more errors later on to be expected a few times:

```
ERROR:  relation "geometry_columns" already exists
ERROR:  must be owner of relation geometry_columns
ERROR:  relation "spatial_ref_sys" already exists
ERROR:  must be owner of relation spatial_ref_sys
```

### Give yourself a CKAN user for debug (optional)

For test purposes you can add a CKAN admin user. Remember to reset the password before making the site live.

    sudo -u www-data paster user add admin email=admin@ckan password=pass --config=ckan.ini
    sudo -u www-data paster sysadmin add admin --config=ckan.ini

### Try CKAN

You can test CKAN on the command-line:
    
    curl http://localhost/data/search

And try a browser to connect to the machine. If its running in Vagrant then the address (from the Vagrantfile) will be: http://192.168.11.11/data/search

You should get CKAN HTML. It's worth checking the logs for errors too:

    less /var/log/ckan/ckan-apache.error.log

Working correctly you should see something like this:
```
[Fri Sep 19 13:43:49 2014] [error] 2014-09-19 13:43:49,484 DEBUG [ckanext.spatial.model.package_extent] Spatial tables defined in memory
[Fri Sep 19 13:43:49 2014] [error] 2014-09-19 13:43:49,491 DEBUG [ckanext.spatial.model.package_extent] Spatial tables already exist
[Fri Sep 19 13:43:49 2014] [error] 2014-09-19 13:43:49,502 DEBUG [ckanext.harvest.model] Harvest tables defined in memory
[Fri Sep 19 13:43:49 2014] [error] 2014-09-19 13:43:49,505 DEBUG [ckanext.harvest.model] Harvest tables already exist
[Fri Sep 19 13:43:50 2014] [error] 2014-09-19 13:43:50,025 CRITI [ckan.lib.uploader] Please specify a ckan.storage_path in your config
[Fri Sep 19 13:43:50 2014] [error]                              for your uploads
```

## 3. Drupal install

For Drupal you will need to complete the configuration of the LAMP stack and get a working drush installation.  Please see https://drupal.org/requirements for detailed requirements.

## Install Drush

For more details about installation of Drush, see here: https://github.com/drush-ops/drush

First get Composer:

    curl -sS https://getcomposer.org/installer | php
    sudo mv composer.phar /usr/local/bin/composer

Now install the latest Drush:

    composer global require drush/drush:dev-master

And add it to the path:

    sed -i '$a\export PATH="$HOME/.composer/vendor/bin:$PATH"' $HOME/.bashrc
    source $HOME/.bashrc

## Install the DGU Drupal Distribution

If using Vagrant, clone the distribution on your host machine before switching to the host machine for the remainder of the instructions.

Get the DGU Drupal Distribution using:

    cd $THIS_REPO/src
    git clone https://github.com/datagovuk/dgu_d7.git

You can install drupal with the following drush command:

````bash
$ sudo mkdir /var/www/drupal
$ sudo chown co:www-data /var/www/drupal
$ cd /src/dgu_d7/
$ drush make distro.make /var/www/drupal/dgu
$ mysql -u root --execute "CREATE DATABASE dgu;"
$ mysql -u root --execute "CREATE USER 'co'@'localhost' IDENTIFIED BY 'pass';"
$ mysql -u root --execute "GRANT ALL PRIVILEGES ON *.* TO 'co'@'localhost';"
$ cd /var/www/drupal/dgu
$ drush --yes --verbose site-install dgu --db-url=mysql://co:pass@localhost/dgu --account-name=admin --account-pass=admin  --site-name='something creative'
```

This will install drupal, download all the required modules and configure the system.  After this step completes
successfully, you should enable some modules:

````bash
$ drush --yes en dgu_site_feature
$ drush --yes en dgu_app dgu_blog dgu_consultation dgu_data_set dgu_data_set_request dgu_footer dgu_forum dgu_glossary dgu_idea dgu_library dgu_linked_data dgu_location dgu_organogram dgu_promo_items dgu_reply dgu_shared_fields dgu_user dgu_taxonomy ckan dgu_search dgu_services dgu_home_page dgu_moderation
````

You will need to configure drupal with the url of your CKAN instance.  We use the following drush commands:
````bash
$ drush vset ckan_url 'http://data.gov.uk/api/';
$ drush vset ckan_apikey 'xxxxxxxxxxxxxxxxxxxxx';
````
You may also check and modify these settings in the admin menu: configuration->system->ckan.

Now fix permissions:
```
$ sudo chown -R co:www-data /var/www/drupal/dgu/sites/default/files
```
Otherwise you'll get messages such as "The specified file temporary://fileKrLiDX could not be copied, because the destination directory is not properly configured. This may be caused by a problem with file or directory permissions. More information is available in the system log."

Drupal uses a second SOLR core for the search. The configuration of this is to be provided soon.

## 4. Drupal content

### Sample content

Those evaluating this distribution will probably want to use the sample content, which creates some sample blog posts, apps etc. This is installed like this:

    $ zcat /src/dgu_d7/sample/dgud7_default_db.sql.gz  | mysql -u root dgu

NB This will delete all other Drupal content and users.

You can now log-in with this user:

    Username: admin
    Password: admin


### Content migration from Drupal 6

For reference purposes, we provide the migration classes for migrating our older Drupal 6 version of data.gov.uk to Drupal version 7.  The order
that we run these tasks is important.  After installation, we run the following drush commands to migrate our web site:

````bash
$ drush migrate-import --group=User --debug
$ drush migrate-import --group=Taxonomy
$ drush migrate-import --group=Files --debug
$ drush migrate-import --group=Datasets --debug
$ drush migrate-import --group=Nodes --debug
$ drush migrate-import --group=Paths --debug
$ drush migrate-import --group=Comments --debug
````

The migration depends on finding drupal variables to tell it where to look to find files and the data,
so, before you can run the migration, you will to add something like the following to your settings.php file:

````php
$conf['drupal6files'] = '/var/www/old_files';
$databases['d6source']['default'] = array(
    'driver' => 'mysql',
    'database' => 'drupal_d6',
    'username' => 'web',
    'password' => 'supersecret',
    'host' => 'localhost',
    'prefix' => '',
);
````

## 5. Additional configuration

### Passwords

For a live deployment it is important to change the passwords from the sample ones. The passwords to change are:

* Drupal accounts, particularly `admin` and 'jason' users (if using the sample database). Log-in as admin and edit the users here: /admin/people
* CKAN `admin` account. Change it with:

    sudo -u www-data paster user setpass admin --config=ckan.ini

* MySQL database for both the `root` and `co`. Use these commands:

    mysql -u root --execute "SET PASSWORD = PASSWORD('new root password');"
    mysql -u -p root --execute "SET PASSWORD FOR 'co'@'localhost' = PASSWORD('new co password');"

And change password in your Drupal settings `/var/www/drupal/dgu/sites/default/settings.php` and reboot Apache:

    sudo apachectl restart

* Postgres database

    sudo -u postgres psql -c "ALTER USER Postgres WITH PASSWORD 'new postgres password';"
    sudo -u postgres psql -c "ALTER USER co WITH PASSWORD 'new co password';"

And change password in your CKAN sqlalchemy setting in `/var/ckan/ckan.ini`:

    sqlalchemy.url = postgresql://dgu:pass@localhost/ckan

and reboot Apache:

    sudo apachectl restart


### Caching

It is likely that you'll want to set-up caching in front of Apache, to massively speed up common requests. This can be achieved with Varnish or Nginx in front of Apache. We suggest:

* Strip any cookies apart from these essential ones: `(flags|SESS[a-z0-9]+|NO_CACHE|auth_tkt|ckan|session_api_[a-z]+)`
* Logged-in users bypass the cache - cookie `SESS[a-z0-9]+`
* assets are kept for 24h - This is cache-safe because a timestamp is added to URLs that CKAN uses e.g. `/assets/css/datagovuk.min.css?1411377399236`, so whenever Grunt runs, a new number is given and the cache will be bypassed because of the new number.


# Orientation

## CKAN Paster commands

When running CKAN paster commands, you should ensure that CKAN's python virtual environment is activated the you are in the CKAN source directory. And you should use the www-data user, to avoid the log permissions problem (see section below).

The virtual environment will normally be actived automatically for the co user, (in the .bashrc). Alternatively you can do it manually:

    source ~/ckan/bin/activate && cd /src/ckan

 You can see that the virtual environment is activated by the presence of the `(ckan)` prefix in the prompt. e.g.:


Examples::

    sudo -u www-data paster create-test-data --config=ckan.ini
    sudo -u www-data paster search-index rebuild --config=ckan.ini
    sudo -u www-data paster --plugin=ckanext-dgu celeryd run concurrency=1 --queue=priority --config=ckan.ini

Find full details of the CKAN paster commands is here: http://docs.ckan.org/en/ckan-2.2/paster.html

## Log permissions

It can happened that you may see CKAN return '500 Internal Server Error' and when looking at the log /var/log/ckan/ckan.log you see this error:

    IOError: [Errno 13] Permission denied: '/var/log/ckan/ckan.log

This can happen when running paster commands and forgetting run them as the `www-data` user as directed. Normally the CKAN logfile is created and written to by apache and hence is owned by user `www-data`. However when running paster commands as the co user it will also write to the log, and if the log happens to roll-over at this time then the co user will now own the logfile. To rectify this, change the ownership:

    sudo chown www-data:www-data /var/log/ckan/ckan.log

The fix for this issue is in the pipeline.

## Grunt and assets

Data.gov.uk uses Grunt to do pre-processing of Javascript and CSS scripts as well as images and it writes timestamps to help with cache versioning.

Puppet will have installed a recent version of NodeJS (0.10.32+) and npm (1.4.28+) plus Grunt. There are two repos with assets which if you change you need to run Grunt before they will be used by CKAN.

Grunt runs on puppet provision, and you can manually run it like this:

    cd /vagrant/src/ckanext-dgu
    grunt
    cd /vagrant/src/shared_dguk_assets
    grunt

There is more about Grunt use here: https://github.com/datagovuk/shared_dguk_assets/blob/master/README.md
P

## Reports

The reports at /data/report should be pre-generated nightly using a cron. e.g.:

    0 6  * * *  www-data  /home/co/ckan/bin/paster --plugin=ckanext-report report generate --config=/var/ckan/ckan.ini


## Harvesting

For harvesting to work you need a cron running every few minutes to put the latest jobs onto the gather queue:

    */10 *  * * *   www-data  /home/co/ckan/bin/paster --plugin=ckanext-harvest harvester run --config=
/var/ckan/ckan.ini

## Backups

The gov_daily.py script performs a number of nightly jobs including creating backups. Read through and see if you need it in all or part. It could be scheduled in the cron:

    0 23  * * *  root  /home/co/ckan/bin/python /vagrant/src/ckanext-dgu/ckanext/dgu/bin/gov_daily.py /var/ckan/ckan.ini


# Puppet notes

## Puppet warnings

These messages will be seen during provisioning with Puppet, and are harmless:

    warning: Could not retrieve fact fqdn
    stdin: is not a tty
    dpkg-preconfigure: unable to re-open stdin: No such file or directory
    warning: Scope(Class[Python]): Could not look up qualified variable '::python::install::valid_versions'; class ::python::install has not been evaluated at /etc/puppet/modules/python/manifests/init.pp:73
    warning: Scope(Class[Python]): Could not look up qualified variable '::python::install::valid_versions'; class ::python::install has not been evaluated at /etc/puppet/modules/python/manifests/init.pp:73

## Puppet apply

When tinkering with the Puppet configuration and rerunning it, it can be frustrating the the `vagrant provision` takes several minutes to run. Much of the time there is no need to have librarian check the puppet module dependencies, and in this case there is a short cut.

You can manually install an updated Puppet CKAN module like this (on the guest):

    sudo -u vagrant rsync -r /vagrant/puppet/modules/dgu_ckan /etc/puppet/modules/dgu_ckan

And run 'puppet apply' as the vagrant user like this:

    sudo FACTER_fqdn=ckan.home puppet apply --modulepath=/etc/puppet/modules /vagrant/puppet/manifests/site.pp

