# Setup

Clone this repo. Switch to `$THIS_REPO/src` and clone all the CKAN source repos ready for development work.

    cd $THIS_REPO/src
    ./git_clone_all.sh

Install Vagrant. Switch to this directory and launch a fully provisioned Virtual Machine:

    vagrant up

To provision an existing machine, rename it to "ckan" and execute the manifest. Inside the VM:

    sudo hostname ckan
    sudo vim /etc/hosts
    # ^ add "127.0.0.1  ckan" to hosts...
    sudo puppet apply /vagrant/puppet/manifests/site.pp

# CKAN Database setup

**IMPORTANT** You must activate the CKAN virtual environment when working on the VM. Eg.:

    source ~/ckan/bin/activate

And setup a useful environment variable... 

    export CKAN_INI=/var/ckan/ckan.ini

#### Option 1: Use test data

    createdb -O dgu ckan --template template_postgis
    paster --plugin=ckanext-ga-report initdb --config=$CKAN_INI
    paster --plugin=ckanext-dgu create-test-data --config=$CKAN_INI
    paster --plugin=ckan search-index rebuild --config=$CKAN_INI

#### Option 2: Download a production database

On the host machine: 

    export CKAN_DUMP_FILE=dgu_as_root_user.2013-07-09.pg_dump.gz
    export URL=co@co-prod1.dh.bytemark.co.uk:/var/backups/ckan/$CKAN_DUMP_FILE
    cd $THIS_REPO
    mkdir -p db_backup && cd db_backup
    rsync --progress $URL $CKAN_DUMP_FILE

On the VM:

    export CKAN_DUMP_FILE=`ls /vagrant/db_backup/ -t |head -n 1` && echo $CKAN_DUMP_FILE
    sudo apachectl stop
    dropdb ckan
    createdb -O dgu ckan --template template_postgis
    pv /vagrant/db_backup/$CKAN_DUMP_FILE | funzip \
      | PGPASSWORD=pass psql -h localhost -U dgu -d ckan 
    sudo apachectl start
    paster --plugin=ckan db upgrade --config=$CKAN_INI
    paster --plugin=ckanext-ga-report initdb --config=$CKAN_INI
    paster --plugin=ckan search-index rebuild --config=$CKAN_INI

### Give yourself a CKAN user for debug:

    paster --plugin=ckan user remove admin --config=$CKAN_INI
    paster --plugin=ckan user add admin email=admin@ckan password=pass --config=$CKAN_INI
    paster --plugin=ckan sysadmin add admin --config=$CKAN_INI
