# Data.gov.uk To Go

This repo provides scripts to install a copy of data.gov.uk's website to your own server. Rebrand it and you have a fully-featured government open data portal.

NB This used to be the 'togo' branch, but that has been removed now - use master.

## About

The UK Government has contributed Data.gov.uk To Go to Github to kick-start the use and development of common open data portal software, beyond the basic CKAN. UK wants to develop it in partnership with other providers of Open Data portals, through the usual Open Source / Github model of forking, pull requests, issues etc. that everyone is encouraged to contribute to.

![Demo image](ckan_sample_data.png)

If you question or issue installing, please refer to open Github issues before creating a new one: https://github.com/datagovuk/dgu-vagrant-puppet/issues

Here are some useful docs: [data.gov.uk guidance](http://datagovuk.github.io/guidance/)
  * Permissions for publisher users - requesting and giving
  * Creating datasets using the form
  * Creating datasets using harvesters, particularly for metadata in DCAT/data.json/CKAN format

David Read
david.read@hackneyworkshop.com

## Overview

Here is an overview of the install process:

* Machine preparation - Vagrant VM or a fresh Ubuntu 12.04 machine
* CKAN source - download from Github
* Puppet provision of the main software packages (Apache, Postgres, SOLR etc) and set-up linux users
* CKAN database setup
* Drupal install
* Additional configuration

## Suggested system requirements

data.gov.uk runs on a single machine specified as follows:

* 24GB RAM
* 8 cores
* 200GB disc

We've not needed to make it work on a lesser machine, but no doubt it could.

For single-user testing, you can certainly run it in less. e.g. we run it on dev VMs with 8 GB RAM.

## 1. Machine preparation & CKAN install

There are two options - you can either use Vagrant to create a virtual machine, or you can use an Ubuntu machine that already exists. Either way, Puppet will be used to do basic set-up of users, install packages and CKAN itself.

### Option 1: Virtual Machine creation

NB We have had issues running this in VMWare and suggest you stick with (free) VirtualBox, using 4.3.14 or later.

NB This setup does not work with a Windows host machine (since it relies on symbolic links).

Before creating the virtual machine, clone this repo to the host machine:

    git clone https://github.com/datagovuk/dgu-vagrant-puppet
    cd dgu-vagrant-puppet

Use the script to clone all the CKAN source repos onto your host machine:

    cd src
    ./git_clone_all.sh
    cd ..

Using Vagrant and Puppet, launch a fully provisioned Virtual Machine as described in this repo:

    vagrant up

Now a great deal should happen. Expect these key stages:

* create the virtual machine (VM)
* boot the VM
* update some key Ubuntu packages like linux-headers
* mount the shared folders

You can generally ignore these warnings if they come up:

* the version of GuestAdditions not matching
* "Could not find the X.Org or XFree86 Window System, skipping."

At this point the shell text goes green and it does the "provision". If this does not start automatically, start it manually (from the host box):

    vagrant provision

The provision is:

* prepare to run librarian (`install_puppet_dependancies.sh`) - install git, update all Ubuntu packages, install ruby and librarian-puppet
* runs librarian-puppet - downloads all puppet modules that are required (listed in Puppetfile) and makes a copy of the CKAN puppet module.
* runs 'puppet apply' (blue output) - installs and configures CKAN and installs some dependencies of Drupal.

Provisioning will take a while, and you can ignore warnings that are listed in the section of this document titled 'Puppet warnings'. If you should suffer errors, please see the section below 'Puppet errors'.

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

    sudo adduser co -u 510 --group sudo
    sudo su co

All further steps are to be carried out from the ssh session under the user 'co' on this target machine.

You need to install some dependencies. Firstly git:

    sudo apt-get install git

Now install ruby and 'librarian-puppet':

    curl -L get.rvm.io | bash -s stable
    source ~/.rvm/scripts/rvm
    rvm requirements
    rvm install 1.8.7
    sudo gem install puppet -v 2.7.19
    sudo gem install highline -v 1.6.1  # need this older version for librarian compatibility with this version of ruby
    sudo gem install librarian-puppet -v 1.0.3

Clone this repo to the machine in /vagrant (to match the vagrant install):

    sudo mkdir /vagrant
    sudo chown co /vagrant
    sudo chgrp co /vagrant
    cd /vagrant
    git clone https://github.com/datagovuk/dgu-vagrant-puppet
    cd /vagrant/dgu-vagrant-puppet

Use the script to clone all the CKAN source repos.

    ln -s /vagrant/dgu-vagrant-puppet/src /vagrant/src
    ln -s /vagrant/dgu-vagrant-puppet/puppet/ /vagrant/puppet
    ln -s /vagrant/dgu-vagrant-puppet/pypi /vagrant/pypi
    ln -s /vagrant/src /src
    cd /src
    ./git_clone_all.sh

Puppet is used to install and configure the main software packages (Apache, Postgres, SOLR etc) and setup linux users.

To provision an existing machine, install the puppet modules:

    sudo /vagrant/puppet/install_puppet_dependancies.sh

and then execute the site manifest now at /etc/puppet/:

    sudo puppet apply /vagrant/puppet/manifests/site.pp

Provisioning will take a while, and you can ignore warnings that are listed in the section of this document titled 'Puppet warnings'. If you should suffer errors, please see the section below 'Puppet errors'.

To automatically activate your CKAN python virtual environment on log-in, it is recommended to add this line to your .bashrc:

    source ~/ckan/bin/activate && cd /src/ckan

and also add this line for the ruby to work properly:

    source ~/.rvm/scripts/rvm


## 2. Extra CKAN setup

(This extra setup will be usefully puppetized in the future)

## Download NLTK Stopwords Corpus

For the auth-theming used by the harvesters you need to install this corpus:

    /home/co/ckan/bin/python -m nltk.downloader stopwords

### Harvesting

Harvester needs a backend, and the default is Redis (installed by puppet).

You need to create the gather and fetch queues by running the consumers briefly:

    sudo -u www-data /home/co/ckan/bin/paster --plugin=ckanext-harvest harvester gather_consumer --config=/var/ckan/ckan.ini
    sudo -u www-data /home/co/ckan/bin/paster --plugin=ckanext-harvest harvester fetch_consumer --config=/var/ckan/ckan.ini

The queues should be left running, either in screen sessions, or preferably using [supervisord](https://github.com/ckan/ckanext-harvest#setting-up-the-harvesters-on-a-production-server).

Meanwhile you need the `harvester run` cron job to run every 10 minutes:

    */10 *  * * *   www-data  /home/co/ckan/bin/paster --plugin=ckanext-harvest harvester run --config=/var/ckan/ckan.ini

### Archiver & QA

To enable the resource cache, broken link checker and 5 star checker:

1. Unless you're just testing the site locally, change the `ckan.cache_url_root` setting in /var/ckan/ckan.ini to reflect the domain where you will host your site. e.g. for data.gov.uk we have:

        ckan.cache_url_root = http://data.gov.uk/data/resource_cache/

2. Keep these two processes running in the background, using screen or ideally supervisord:

        sudo -u www-data /home/co/ckan/bin/paster --plugin=ckan celeryd run concurrency=1 --queue=priority --config=/var/ckan/ckan.ini
        sudo -u www-data /home/co/ckan/bin/paster --plugin=ckan celeryd run concurrency=4 --queue=bulk --config=/var/ckan/ckan.ini

3. Trigger the weekly refreshes using this cron setting:

        0 22 * * 5  www-data  /home/co/ckan/bin/paster --plugin=ckanext-archiver archiver update --config=/var/ckan/ckan.ini

The Archiver and QA extensions are explained later on in this guide.

## 3. CKAN Database setup

**IMPORTANT** You must activate the CKAN virtual environment when working on the VM. Eg.:

    source ~/ckan/bin/activate

And make sure you run paster commands as `co` user from the `/src/ckan` or `/vagrant/src/ckan` directory.

After running puppet, a fresh database is created for you. If you need to create it again then you can do it like this:

    createdb -O dgu ckan --template template_postgis

Now you need to create the tables for the various extensions:

    sudo -u www-data /home/co/ckan/bin/paster --plugin=ckanext-packagezip packagezip init --config=/var/ckan/ckan.ini
    sudo -u www-data /home/co/ckan/bin/paster --plugin=ckanext-issues issues init_db --config=/var/ckan/ckan.ini

#### Option 1: Use test data

Sample data is provided to demonstrate CKAN. It comprises 5 sample datasets and is loaded like this:

    sudo -u www-data /home/co/ckan/bin/paster --plugin=ckanext-dgu create-test-data --config=/var/ckan/ckan.ini

The sample data looks like this:

![Demo image](ckan_sample_data.png)

#### Option 2: Download an existing database

At data.gov.uk we transfer database by first creating a dump (using pg_dump and gzip) and transfer it to a test server or local machine for development. Here is an example transfer - adapt the commands to transfer your own database dumps from your own server.

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
    sudo -u www-data /home/co/ckan/bin/paster --plugin=ckan db upgrade --config=/var/ckan/ckan.ini
    sudo -u www-data /home/co/ckan/bin/paster --plugin=ckan search-index rebuild --config=/var/ckan/ckan.ini

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

    sudo -u www-data /home/co/ckan/bin/paster --plugin=ckan user add admin email=admin@ckan password=pass --config=/var/ckan/ckan.ini
    sudo -u www-data /home/co/ckan/bin/paster --plugin=ckan sysadmin add admin --config=/var/ckan/ckan.ini

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

## 4. Drupal install

For Drupal you will need to complete the configuration of the LAMP stack and get a working drush installation, as explained below.  For more detailed requirements, please refer to https://drupal.org/requirements .

### Install Drush

For more details about installation of Drush, see here: https://github.com/drush-ops/drush

First get Composer:

    curl -sS https://getcomposer.org/installer | php
    sudo mv composer.phar /usr/local/bin/composer

Now install the latest Drush:

    composer global require drush/drush

And add it to the path:

    sed -i '$a\export PATH="$HOME/.composer/vendor/bin:$PATH"' $HOME/.bashrc
    source $HOME/.bashrc

### Install the DGU Drupal Distribution

You can install the DGU Drupal Distribution with the following commands:

````bash
sudo mkdir /var/www/drupal
sudo chown co:www-data /var/www/drupal
cd /src/dgu_d7/
drush make distro.make /var/www/drupal/dgu
mysql -u root --execute "CREATE DATABASE dgu;"
mysql -u root --execute "CREATE USER 'co'@'localhost' IDENTIFIED BY 'pass';"
mysql -u root --execute "GRANT ALL PRIVILEGES ON *.* TO 'co'@'localhost';"
cd /var/www/drupal/dgu
drush --yes --verbose site-install dgu --db-url=mysql://co:pass@localhost/dgu --account-name=admin --account-pass=admin  --site-name='something creative'
```

This will install Drupal, download all the required modules and configure the system.  In the `site-install` command you can ignore two errors at the end about sending e-mails, due to sendmail being missing. E-mail functionality will need to be fixed for a production system.

After this step completes successfully, you should enable some modules:

````bash
drush --yes en dgu_app dgu_blog dgu_consultation dgu_data_set dgu_data_set_request dgu_footer dgu_forum dgu_glossary dgu_idea dgu_library dgu_linked_data dgu_location dgu_moderation dgu_notifications dgu_organogram dgu_print dgu_reply dgu_search dgu_services dgu_user ckan
````

You will need to configure drupal with the url of your CKAN instance.  We use the following drush commands:
````bash
drush vset ckan_url 'http://data.gov.uk/api/';
drush vset ckan_apikey 'xxxxxxxxxxxxxxxxxxxxx';
````
You may also check and modify these settings in the admin menu: configuration->system->ckan.

Now fix permissions:
```
sudo chown -R co:www-data /var/www/drupal/dgu/sites/default/files
```
Otherwise you'll get messages such as "The specified file temporary://fileKrLiDX could not be copied, because the destination directory is not properly configured. This may be caused by a problem with file or directory permissions. More information is available in the system log."

Drupal uses a second SOLR core for the search. The configuration of this is to be provided soon.

## 5. Drupal content

### Sample content

Those evaluating this distribution will probably want to use the sample content, which creates some sample blog posts, apps etc. This is installed like this:

    zcat /src/dgu_d7/sample/dgud7_default_db.sql.gz  | mysql -u root dgu

NB This will delete all other Drupal content and users.

You can now log-in by executing 'drush uli' in Drupal root folder.
This command generates one time login link, you can change admin password once logged in.

If you get the message "The website encountered an unexpected error. Please try again later." please see the section below "Debugging Drupal".


## 6. Additional configuration

### Passwords

For a live deployment it is important to change the passwords from the sample ones. The passwords to change are:

* Drupal accounts, particularly `admin` and 'jason' users (if using the sample database). Log-in as admin and edit the users here: /admin/people

* CKAN `admin` account. Change it with:

        sudo -u www-data /home/co/ckan/bin/paster --plugin=ckan user setpass admin --config=/var/ckan/ckan.ini

* HTTP Basic Auth around Drupal services. Change the password CKAN uses to contact the Drupal services API by editing in `/var/ckan/ckan.ini` the value for `dgu.xmlrpc_password` to be a new password:

        dgu.xmlrpc_password = newpassword

    And then set that same password to be the one accepted by the API using:

        sudo htpasswd /var/www/api_users ckan

    and reboot Apache:

        sudo apachectl restart

* MySQL database for both the `root` and `co`. Use these commands:

        mysql -u root --execute "SET PASSWORD = PASSWORD('new root password');"
        mysql -u -p root --execute "SET PASSWORD FOR 'co'@'localhost' = PASSWORD('new co password');"

    And change password in your Drupal settings `/var/www/drupal/dgu/sites/default/settings.php` and reboot Apache:

        sudo apachectl restart

* Postgres database:

        sudo -u postgres psql -c "ALTER USER Postgres WITH PASSWORD 'new postgres password';"
        sudo -u postgres psql -c "ALTER USER co WITH PASSWORD 'new co password';"

And change password in your CKAN sqlalchemy setting in `/var/ckan/ckan.ini`:

    sqlalchemy.url = postgresql://dgu:pass@localhost/ckan

and reboot Apache:

    sudo apachectl restart

* SSH authentication. The install provides ssh access to the data.gov.uk team, and clearly this should be changed for other organizations. Remove the irrelevant people's lines from this file:

        /home/co/.ssh/authorized_keys


### Syncing publishers and datasets from CKAN to Drupal

Drupal needs to get data from CKAN for forms creating Data Requests and Apps (for example).

It is suggested that this data is synchronized hourly with a cron.

To install the dependencies for the syncing:
```
cd /var/www/drupal/dgu
drush composer-rebuild
cd /var/www/drupal/dgu/sites/default/files/composer
composer install
```

You need to create a sysadmin user in CKAN that Drupal can use to get the data:
```
sudo -u www-data /home/co/ckan/bin/paster --plugin=ckan user add frontend email=a@b.com password=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
sudo -u www-data /home/co/ckan/bin/paster --plugin=ckan sysadmin add frontend
```
Note the apikey from the output of the first command e.g.:

    'apikey': u'17a4a2fa-edf9-479e-bd71-1c0620fe457d'

Now configure how Drupal contacts CKAN: Browse to: /admin/config/system/ckan (On vagrant it is: http://192.168.11.11/admin/config/system/ckan )
And configure the URL for CKAN (adding `/api/`) and the `apikey` from the previous step. e.g.
```
CKAN API URL = http://192.168.11.11/api/
API key = 17a4a2fa-edf9-479e-bd71-1c0620fe457d
CKAN editor role = data publisher
CKAN admin role = data publisher
```
(NB: leave the revision options the same)

To (re)sync all publishers you can execute:

    drush ckan_resync_publisher all

These sync commands create a lock to avoid parallel execution.
If you stop the command (ctrl+c) this lock isn't remove it, to remove it please append ```--kill``` to the command:

    drush ckan_resync_publisher all --kill

You can also resync a single publisher:

    drush ckan_resync_publisher 041e93f9-bf4e-48ec-b779-6bda9588ef55

There is also similar command for syncing datasets:

    drush ckan_resync_dataset

and for datasets and publishers in one go:

    drush ckan_resync_all

(NB If you have no dataset in CKAN, then you'll get an SQL error when syncing them.)

### Caching

It is likely that you'll want to set-up caching in front of Apache, to massively speed up common requests. This can be achieved with Varnish or Nginx in front of Apache. We suggest:

* Strip any cookies apart from these essential ones: `(flags|SESS[a-z0-9]+|NO_CACHE|auth_tkt|ckan|session_api_[a-z]+)`
* Logged-in users bypass the cache - cookie `SESS[a-z0-9]+`
* assets are kept for 24h - This is cache-safe because a timestamp is added to URLs that CKAN uses e.g. `/assets/css/datagovuk.min.css?1411377399236`, so whenever Grunt runs, a new number is given and the cache will be bypassed because of the new number.

### Site Analytics/Usage (Google Analytics)

The Google Analytics data is shown here: http://data.gov.uk/data/site-usage
To set this up, you need to:

1. Setup Google Analytics account & tracking - see: https://github.com/datagovuk/ckanext-ga-report/blob/master/README.md#setup-google-analytics

2. Add the configuration to your ckan.ini, customizing the values for the first 2 options:

        googleanalytics.id = UA-1010101-1
        googleanalytics.account = Account name (e.g. data.gov.uk, see top level item at https://www.google.com/analytics)
        googleanalytics.token.filepath = /var/ckan/ga_auth_token.dat
        ga-report.period = monthly
        ga-report.bounce_url = /data/search

3. Create the database tables:

        sudo -u www-data /home/co/ckan/bin/paster --plugin=ckanext-ga-report initdb --config=/var/ckan/ckan.ini

4. Enable the extension by adding it to the list of `ckan.plugins` in ckan.ini:

        ckan.plugins = ... ga-report

5. Generate an OAUTH token using the instructions: https://github.com/datagovuk/ckanext-ga-report/blob/master/README.md#authorization The paster command is:

        sudo -u www-data /home/co/ckan/bin/paster --plugin=ckanext-ga-report getauthtoken --config=/var/ckan/ckan.ini
        mv token.dat /var/ckan/ga_auth_token.dat

6. Now you can load the GA data into CKAN. Run it the first time on the command-line to check it works:

        sudo -u www-data /home/co/ckan/bin/paster --plugin=ckanext-ga-report loadanalytics latest --config=/var/ckan/ckan.ini

Then you can add it as a cron job. e.g. add it to /etc/cron.d/ckan
```
0 22  * * *  www-data  /home/co/ckan/bin/paster --plugin=ckanext-ga-report loadanalytics latest --config=/var/ckan/ckan.ini

```

# Orientation

## CKAN Paster commands

When running CKAN paster commands, you should ensure that:

* you specify the path to paster in the virtualenv (in the future you might just ensure you've activated CKAN's python virtual environment, but that doesn't work when you sudo)
* you are in the CKAN source directory (/src/ckan)
* use the www-data user, to avoid the log permissions problem (see section below)

You can see that the virtual environment is activated by the presence of the `(ckan)` prefix in the prompt. e.g.:

    (ckan)co@precise64:/src/ckan$

Note you do need to specify --config because although ckan now gets it from the CKAN_INI environment variable (this is due to a recently introduced change to ckan), that is not available when you sudo.

Examples:

    sudo -u www-data /home/co/ckan/bin/paster search-index rebuild --config=/var/ckan/ckan.ini
    sudo -u www-data /home/co/ckan/bin/paster user user_d1 --config=/var/ckan/ckan.ini
    sudo -u www-data /home/co/ckan/bin/paster --plugin=ckanext-dgu create-test-data --config=/var/ckan/ckan.ini
    sudo -u www-data /home/co/ckan/bin/paster --plugin=ckanext-dgu celeryd run concurrency=1 --queue=priority --config=/var/ckan/ckan.ini

You can add `--help` to list commands and find out more about one. Find full details of the CKAN paster commands is here: http://docs.ckan.org/en/ckan-2.2/paster.html

## CKAN Config file

The ckan config file is `/var/ckan/ckan.ini`. If you change any options, for them to take effect in the web interface you need to restart apache:

    sudo /etc/init.d/apache2 graceful

## CKAN Logs

The main CKAN log file is: `/var/log/ckan/ckan.log`

Errors go to: `/var/log/ckan/ckan-apache.error.log`

The log levels are set in /var/ckan/ckan.ini, so to get the debug logging from ckan you can change the level in the `logger_ckan` section. i.e. change it to:
```
[logger_ckan]
level = DEBUG
handlers = console, file
qualname = ckan
propagate = 0
```
(and obviously restart apache to take effect)

The Celery queues workers (Archiver & QA) log to: `/var/log/ckan/celeryd.log`

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

    */10 *  * * *   www-data  /home/co/ckan/bin/paster --plugin=ckanext-harvest harvester run --config=/var/ckan/ckan.ini

## Archiver & QA

The 'Archiver' extension downloads all the data files and notes if the link is 'broken' or not. The 'QA' extension examines the downloaded data files, mainly to determine the format, and give the dataset a rating against the 5 Stars of Openness ("Openness Score").

The 'Archiver' is triggered when a dataset is created or modified, and that in turn triggers the 'QA'. In addition, to links going rotten at a later date, it is sensible to trigger the Archival (and thus QA) on a weekly basis using a cron job.

Archiver and QA work asynchronously from the rest of CKAN. Jobs for them are put onto a celery queue, and by 'running' the queue the Archiver and QA carry out their jobs. So for the Archiver and QA to work, you need to have two Celery processes running all the time, either in a screen session or preferably using supervisord.

The list of jobs in the queue are stored in Redis (previously the jobs were stored in the `kombu_message` table in the database - if this is still being used you need to add the `[app:celery]` section to your ckan config - see `ckan.ini.erb`).

In fact there are two queues for the jobs - 'priority' deals with the trickle of new and updated datasets and 'bulk' deals with the weekly refresh and other longer updates.

To see how many jobs are on a queue:

    redis-cli -n 1 LLEN priority
    redis-cli -n 1 LLEN bulk

To clean a queue (delete all of its the queued jobs):

    redis-cli -n 1 DEL priority
    redis-cli -n 1 DEL bulk

To schedule a dataset to be archived (and then QA'd):

    sudo -u www-data /home/co/ckan/bin/paster --plugin=ckanext-archiver archiver update cabinet-office-energy-use --config=$CKAN_INI

or to archive all of a publisher's datasets (goes onto bulk queue):

    sudo -u www-data /home/co/ckan/bin/paster --plugin=ckanext-archiver archiver update cabinet-office --config=$CKAN_INI

You can follow the logs of the Archiver & QA in `/var/log/ckan/celeryd.log`.

## Backups (gov_daily)

The gov_daily.py script performs a number of nightly jobs including creating backups and getting the Site Analytics Google Analytics info. Read through and see if you need it in all or part. You can specify a parameter to just do the backup for example. It could be scheduled in the cron:

    0 23  * * *  root  /home/co/ckan/bin/python /vagrant/src/ckanext-dgu/ckanext/dgu/bin/gov_daily.py backup /var/ckan/ckan.ini

## Running in paster

When developing CKAN it is often helpful to use the pdb debugging tool. For this to work, you need to run CKAN in paster (instead of apache).

Run CKAN in paster:

    stty echo; sudo -u www-data /home/co/ckan/bin/paster serve /var/ckan/ckan.ini --reload

In the code insert your pdb breakpoint (e.g. in the data controller):

    import pdb; pdb.set_trace()

In your browser access the site via port 5000 (e.g. for vagrant):

    http://192.168.11.11:5000/data/search

Occasionally when working with pdb you will find it goes into a mode where nothing you type appears on the screen. The solution without having to start a new terminal is to type on the command-line (blind):

    stty echo

## Paster shell

You can get a python shell which has the database loaded:

    sudo -u www-data /home/co/ckan/bin/paster --plugin=pylons shell /var/ckan/ckan.ini

## Running ckan tests

The core ckan tests can be run, but need to use the core ckan solr schema, for which you need to set-up a new solr core.

    sed 's/8983\/solr/8983\/solr\/ckan-2.2/g' test-core.ini > test-core-dread.ini

TBC

## Debugging Drupal

### "The website encountered an unexpected error. Please try again later."

To find out what the error is behind this web error page, as long as it is not a public machine you can increase the debug level using this command:
```
cd /var/www/drupal/dgu
drush vset -y error_level 2
```
and request the page again.

# Puppet notes

## Puppet warnings

These messages may be seen during provisioning with Puppet, and are harmless:

    warning: Could not retrieve fact fqdn
    stdin: is not a tty
    dpkg-preconfigure: unable to re-open stdin: No such file or directory
    warning: Scope(Class[Python]): Could not look up qualified variable '::python::install::valid_versions'; class ::python::install has not been evaluated at /etc/puppet/modules/python/manifests/init.pp:73
    warning: Scope(Class[Python]): Could not look up qualified variable '::python::install::valid_versions'; class ::python::install has not been evaluated at /etc/puppet/modules/python/manifests/init.pp:73
    The directory '/home/vagrant/.cache/pip/http' or its parent directory is not owned by the current user and the cache has been disabled. Please check the permissions and owner of that directory. If executing pip with sudo, you may want sudo's -H flag.
    duplicated key at line 165 ignored: :queue_type
    ==> default: /home/co/ckan/local/lib/python2.7/site-packages/pip/_vendor/requests/packages/urllib3/util/ssl_.py:318: SNIMissingWarning: An HTTPS request has been made, but the SNI (Subject Name Indication) extension to TLS is not available on this platform. This may cause the server to present an incorrect TLS certificate, which can cause validation failures. You can upgrade to a newer version of Python to solve this. For more information, see https://urllib3.readthedocs.org/en/latest/security.html#snimissingwarning.
    ==> default:   SNIMissingWarning
    ==> default: /home/co/ckan/local/lib/python2.7/site-packages/pip/_vendor/requests/packages/urllib3/util/ssl_.py:122: InsecurePlatformWarning: A true SSLContext object is not available. This prevents urllib3 from configuring SSL appropriately and may cause certain SSL connections to fail. You can upgrade to a newer version of Python to solve this. For more information, see https://urllib3.readthedocs.org/en/latest/security.html#insecureplatformwarning.
    ==> default:   InsecurePlatformWarning

## Puppet errors

Despite aiming to keep these scripts working without error, 'Puppet apply' might possibly fail.

If 'puppet apply' fails (e.g. during 'provision') then you see it end with this red text:

    The SSH command responded with a non-zero exit status. Vagrant
    assumes that this means the command failed. The output for this command
    should be in the log above. Please read the output to determine what
    went wrong.

At this point you will usually see lots of yellow warnings "Skipping because of failed dependencies" peppered amongst the blue lines. The art of finding out the cause of the failure is to scroll up to find the *first* of these yellow warnings and look for the error in the line or two above this.

It is always worth trying running puppet again (either with `vagrant provision` or puppet apply - see below) in case it was a one-off problem.

### Pylons and Setuptools

Depending on the order which puppet installs the python packages, you may well get an error to do with installing Pylons, PasteScript and PasteDeploy. e.g.:

    err: /Stage[main]/Dgu_ckan/Dgu_ckan::Pip_package[Pylons==0.9.7]/Exec[pip_install_Pylons==0.9.7]/returns: change from notrun to 0 failed: /home/co/ckan/bin/pip install --no-index --find-links=file:///vagrant/pypi --log-file /home/co/ckan/pip.log Pylons==0.9.7 returned 1 instead of one of [0] at /etc/puppet/modules/dgu_ckan/manifests/pip_package.pp:23

It is a known problem and can usually be solved if you simple rerun the 'puppet apply' / 'vagrant provision' step. You can also solve it manually on the box:

    /home/co/ckan/bin/pip install --no-index --find-links=file:///vagrant/pypi PasteScript==1.7.5
    /home/co/ckan/bin/pip install --no-index --find-links=file:///vagrant/pypi Pylons==0.9.7

## SOLR

We've seen an issue where SOLR doesn't work properly the first time and when puppet tries to run 'paster db init' style commands you see this error:

    WARNI [ckan.lib.search] Problems were found while connecting to the SOLR server
    ERROR [ckan.lib.search.common] HTTP code=503, reason=Service Unavailable

This can usually be fixed by restarting SOLR, via its java environment 'jetty':

    sudo service jetty restart

and check whether the start-up log:

    less /usr/share/solr/solr-4.3.1/example/logs/solr.log

is full of errors or succeeds with something like:

    Started SocketConnector@0.0.0.0:8983


## Puppet apply

When tinkering with the Puppet configuration and rerunning it, it can be frustrating the the `vagrant provision` takes several minutes to run. Much of the time there is no need to have librarian check the puppet module dependencies, and in this case there is a short cut.

You can manually install an updated Puppet CKAN module like this (on the guest):

    sudo -u vagrant rsync -r /vagrant/puppet/modules/dgu_ckan/ /etc/puppet/modules/dgu_ckan/

And run 'puppet apply' as the vagrant user like this:

    sudo FACTER_fqdn=ckan.home puppet apply --modulepath=/etc/puppet/modules /vagrant/puppet/manifests/site.pp

