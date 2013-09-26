# Setup

Get a safe, stable version of puppet.
    sudo apt-get update
    sudo apt-get install sudo apt-get install puppet=2.7.11-1ubuntu2.4

Boot a VM.
    vagrant up

##### Option 1: Configure against the live Puppet Master.

    sudo ln -fs /vagrant/puppet/tmp.conf /etc/puppet/tmp.conf
    
    # /etc/hosts
    46.43.41.25 puppet

    export FACTER_CKAN=true
    export FACTER_CKAN=false
    sudo -E puppet agent --test

##### Option 2: Run a local Puppet Master.

    See [puppet/README.md].


# Migration (TODO rewrite)

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
       # is it just me that gets a benign failure on upgrade in init_const_data?
    # If the database is pre-CKAN 2 then run the manual migrations in the pad:
    # http://etherpad.co-dev1.dh.bytemark.co.uk/p/ckan2
    paster --plugin=ckan search-index rebuild --config=$CKAN_INI

### Give yourself a CKAN user for debug:

    paster --plugin=ckan user remove admin --config=$CKAN_INI
    paster --plugin=ckan user add admin email=admin@ckan password=pass --config=$CKAN_INI
    paster --plugin=ckan sysadmin add admin --config=$CKAN_INI

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

### Common errors

* `multiple values encountered for non multiValued field groups: [david, roger]`

SOLR complains of this when running core ckan tests with the DGU schema. Ideally we'd have SOLR multicore to have the default CKAN schema running. But we don't have this in vagrant yet, so use the dgu-vagrant-puppet branch for non-DGU ckan to test this code.

* `sqlalchemy.exc.OperationalError: (OperationalError) no such table: user`

This is caused by running the ckan tests with SQLite, rather than Postgres. Ensure you use `--with-pylons=test-core.ini` rather than the default `test.ini`. It would be good to fix up SQLite soon - it is an issue with it dropping all tables before tests spuriously.


# Changing Python requirements

1. Add new requirement (eg. `PyMollom==0.1` to init.pp).
2. Add the archive to this repository.

    cd pypi
    pip install --download_cache="." "PyMollom==0.01"

