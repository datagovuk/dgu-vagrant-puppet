# data.gov.uk to go

This repo provides scripts to install a copy of data.gov.uk's website to your own server. Rebrand it and you have a fully-featured government open data portal.

Here is an overview:
1. Machine preparation - Vagrant VM or a fresh Ubuntu 12.04 machine
2. CKAN source - download from Github
3. Virtual machine creation using Vagrant. (A fresh machine running Ubuntu 12.04 (Precise) works just as well.)
3. Puppet provision of the main software packages (Apache, Postgres, SOLR etc) and set-up linux users
4. CKAN database setup
5. Data load (test data - optional)
6. Drupal install

### Suggested system requirements:

* 24GB RAM
* 8 cores
* 200GB disc

## 1. Machine preparation

### Download this build repo from Github

Clone this repo (its path will now be referred to as $THIS_REPO) and switch to the to-go branch:

    git clone https://github.com/datagovuk/dgu-vagrant-puppet.git
    cd dgu-vagrant-puppet
    git checkout togo

### Option 1: Virtual Machine creation

Install Vagrant. Launch a fully provisioned Virtual Machine as described in this repo:

    cd $THIS_REPO
    vagrant up
    vagrant ssh

The prompt will change to show your terminal is connected to the virtual machine. All further steps are from this ssh session on the VM.

### Option 2: Fresh machine preparation

Instead of using a virtual-machine it is perfectly fine alternative to use a non-virtual machine, freshly installed with Ubuntu 12.04. The Puppet scripts assume the name of the machine is 'ckan', so you need to ssh to it and rename it:

    sudo hostname ckan
    sudo vim /etc/hosts
    # ^ add "127.0.0.1  ckan" to hosts...

Puppet also assumes your home user is 'co', so ensure that is used.

All further steps are to be carried out from the ssh session on this target machine.

## 2. CKAN source - download from Github

Use the script to clone all the CKAN source repos.

If using a Vagrant VM, do this step on the host machine, not the VM.

You may need to install git first. 

    cd $THIS_REPO/src
    ./git_clone_all.sh

## 3. Puppet provision

Puppet is used to install and configure the main software packages (Apache, Postgres, SOLR etc) and setup linux users.

To provision an existing machine, install the puppet modules:

    sudo /vagrant/puppet/install_puppet_dependancies.sh

and then execute the site manifest now at /etc/puppet/:

    sudo puppet apply /vagrant/puppet/manifests/site.pp

You can ignore this warning:

    warning: Could not retrieve fact fqdn

# CKAN Database setup

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
    rsync --progress co@co-prod1.dh.bytemark.co.uk:/var/backups/ckan/dgu.2013-07-09.pg_dump.gz /vagrant/db_backup/

Then load the dump in:

    export CKAN_DUMP_FILE=`ls /vagrant/db_backup/ -t |head -n 1` && echo $CKAN_DUMP_FILE
    sudo apachectl stop
    dropdb ckan
    createdb -O dgu ckan --template template_postgis
    pv /vagrant/db_backup/$CKAN_DUMP_FILE | funzip \
      | PGPASSWORD=pass psql -h localhost -U dgu -d ckan
    sudo apachectl start
    paster db upgrade --config=ckan.ini
    paster search-index rebuild --config=ckan.ini

### Give yourself a CKAN user for debug (optional)

For test purposes you can add a CKAN admin user. Remember to reset the password before making the site live.

    paster user add admin email=admin@ckan password=pass --config=ckan.ini
    paster sysadmin add admin --config=ckan.ini

### Paster commands

The VM opens in the ckan directory with the virtualenv activated and there is a symlink to the ckan.ini there, making it easy to run paster commands. 

Warning: Since apache runs as www-data user, reading and writing log and session files, you may get problems if you run paster as vagrant user. To avoid issue, run paster commands ``sudo -u www-data paster``. However, most of the time you can get away with it.

Examples::

    paster create-test-data --config=ckan.ini
    paster search-index rebuild --config=ckan.ini
    paster --plugin=ckanext-dgu celeryd run concurrency=1 --queue=priority --config=ckan.ini

### Testing

Examples::

    nosetests --ckan --with-pylons=test-core.ini ckan/tests/
    nosetests --ckan --with-pylons=../ckanext-spatial/test-core.ini ../ckanext-spatial/ckanext/spatial/tests

### Common error messages

* `multiple values encountered for non multiValued field groups: [david, roger]`

SOLR complains of this when running core ckan tests with the DGU schema. Ideally we'd have SOLR multicore to have the default CKAN schema running. But we don't have this in vagrant yet, so use the dgu-vagrant-puppet branch for non-DGU ckan to test this code.

* `sqlalchemy.exc.OperationalError: (OperationalError) no such table: user`

This is caused by running the ckan tests with SQLite, rather than Postgres. Ensure you use `--with-pylons=test-core.ini` rather than the default `test.ini`. It would be good to fix up SQLite soon - it is an issue with it dropping all tables before tests spuriously.


# Changing Python requirements

If you change the Python requirements/dependencies, then you need change a couple of things to make sure it installs:

1. Tell Puppet to install it (eg. `PyMollom==0.1` to init.pp).
2. Add the Python module to this repo's pypi folder:

    cd pypi
    pip install --download_cache="." "PyMollom==0.01"

