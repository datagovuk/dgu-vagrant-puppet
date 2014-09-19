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

### Download this build repo from Github

Clone this repo (its path will now be referred to as $THIS_REPO) and switch to the 'togo' branch:

    git clone https://github.com/datagovuk/dgu-vagrant-puppet.git
    cd dgu-vagrant-puppet
    git checkout togo

### Option 1: Virtual Machine creation

Before creating the virtual machine, use the script to clone all the CKAN source repos onto your host machine.

You may need to install git first.

    cd $THIS_REPO/src
    ./git_clone_all.sh

Now install Vagrant. Launch a fully provisioned Virtual Machine as described in this repo:

    cd $THIS_REPO
    vagrant up

Provisioning will take a while, and you can ignore warnings that are listed in the section of this document titled 'Vagrant warnings'.

    vagrant ssh

The prompt will change to show your terminal is connected to the VM, you will be logged in as the vagrant user. 
All further steps are from this ssh session on the VM after you have changed your user to 'co' with:

    sudo su co


### Option 2: Fresh machine preparation

Instead of using a virtual-machine it is perfectly fine alternative to use a non-virtual machine, freshly installed with Ubuntu 12.04. The Puppet scripts assume the name of the machine is 'ckan', so you need to ssh to it and rename it:

    sudo hostname ckan
    sudo vim /etc/hosts
    # ^ add "127.0.0.1  ckan" to hosts...

Puppet also assumes your home user is 'co', so ensure that is created and can login as sudo.

    sudo adduser co
    sudo visudo
    su co

You need to install some dependencies:

    sudo apt-get install rubygems git
    sudo gem install librarian-puppet -v 1.0.3

And move the dgu-vagrant-puppet repo to the place where it would end up if using Vagrant:

    mv dgu-vagrant-puppet /vagrant

All further steps are to be carried out from the ssh session under the user 'co' on this target machine.

Use the script to clone all the CKAN source repos.

You may need to install git first. 

    cd $THIS_REPO/src
    ./git_clone_all.sh

Puppet is used to install and configure the main software packages (Apache, Postgres, SOLR etc) and setup linux users.

To provision an existing machine, install the puppet modules:

    sudo /vagrant/puppet/install_puppet_dependancies.sh

and then execute the site manifest now at /etc/puppet/:

    sudo puppet apply /vagrant/puppet/manifests/site.pp

Provisioning will take a while, and you can ignore warnings that are listed in the section of this document titled 'Vagrant warnings'.

To automatically activate your CKAN python virtual environment on log-in, it is recommended to add this line to your .bashrc:

    source ~/ckan/bin/activate && cd /src/ckan


## 2. CKAN Database setup


**IMPORTANT** You must activate the CKAN virtual environment when working on the VM. Eg.:

    source ~/ckan/bin/activate

And make sure you run paster commands from the /vagrant/src/ckan directory.

#### Option 1: Use test data

    createdb -O dgu ckan --template template_postgis
    paster --plugin=ckanext-ga-report initdb --config=ckan.ini
    paster --plugin=ckanext-dgu create-test-data --config=ckan.ini
    paster search-index rebuild --config=ckan.ini

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
    paster db upgrade --config=ckan.ini
    paster search-index rebuild --config=ckan.ini

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

    paster user add admin email=admin@ckan password=pass --config=ckan.ini
    paster sysadmin add admin --config=ckan.ini

### Test CKAN

You can test CKAN on the command-line:
    
    curl -i http://localhost/data/search

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

For Drupal you will need to complete the configuration of the LAMP stack and get a working drush installation.  Please see https://drupal.org/requirements for detailed requirements. You can get drush and it's installation instructions from
here: https://github.com/drush-ops/drush

Get the DGU Drupal Distribution using:

    git clone https://github.com/datagovuk/dgu_d7.git

You can install drupal with the following drush command:

````bash
$ drush make distro.make /var/www/
$ drush --yes --verbose site-install dgu --db-url=mysql://user:pass@localhost/db_name --account-name=admin --account-pass=password  --site-name='something creative'
```

This will install drupal, download all the required modules and configure the system.  After this step completes
successfully, you should enable some modules:

````bash
$ drush --yes en dgu_site_feature  
$ drush --yes en composer_manager  
$ drush --yes en dgu_app dgu_blog dgu_consultation dgu_data_set dgu_data_set_request dgu_footer dgu_forum dgu_glossary dgu_idea dgu_library dgu_linked_data dgu_location dgu_organogram dgu_promo_items dgu_reply dgu_shared_fields dgu_user dgu_taxonomy ckan dgu_search dgu_services dgu_home_page
$ drush --yes en ckan
````

You will need to configure drupal with the url of your CKAN instance.  We use the following drush commands:
````bash
$ drush vset ckan_url 'http://data.gov.uk/api/';
$ drush vset ckan_apikey 'xxxxxxxxxxxxxxxxxxxxx';
````
You may also check and modify these settings in the admin menu: configuration->system->ckan.

We have also written some migration classes for migrating our existing Drupal 6 web site to version 7.  The order
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

Drupal uses a second SOLR core.

## 4. Additional configuration

In this example, both Drupal and CKAN are served from a single vhost of Apache. An example is provided: resources/apache.vhost

For a live deployment it would make sense to adjust the database passwords.

# Orientation

## CKAN Paster commands

When running CKAN paster commands, you should ensure that CKAN's python virtual environment is activated the you are in the CKAN source directory.

The virtual environment will normally be actived automatically for the co user, (in the .bashrc). Alternatively you can do it manually:

    source ~/ckan/bin/activate && cd /src/ckan

 You can see that the virtual environment is activated by the presence of the `(ckan)` prefix in the prompt. e.g.:


Examples::

    paster create-test-data --config=ckan.ini
    paster search-index rebuild --config=ckan.ini
    paster --plugin=ckanext-dgu celeryd run concurrency=1 --queue=priority --config=ckan.ini

Find full details of the CKAN paster commands is here: http://docs.ckan.org/en/ckan-2.0.2/paster.html

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


# Puppet warnings

These messages will be seen during provisioning with Puppet, and are harmless:

    warning: Could not retrieve fact fqdn
    stdin: is not a tty
    dpkg-preconfigure: unable to re-open stdin: No such file or directory
    warning: Scope(Class[Python]): Could not look up qualified variable '::python::install::valid_versions'; class ::python::install has not been evaluated at /etc/puppet/modules/python/manifests/init.pp:73
    warning: Scope(Class[Python]): Could not look up qualified variable '::python::install::valid_versions'; class ::python::install has not been evaluated at /etc/puppet/modules/python/manifests/init.pp:73

