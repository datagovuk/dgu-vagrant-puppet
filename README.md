# Setup

Install Vagrant. Switch to this directory and launch a fully provisioned Virtual Machine:

    vagrant up

To provision an existing machine, execute:

    sudo puppet apply site.pp

# CKAN Database setup

On a fresh machine, CKAN needs to fil out the database.  Initialise CKAN table structure:

    paster --plugin=ckan db init --config=$CKAN_INI 

Install ckanext-ga-report plugin

    cd /vagrant/src/ckanext-ga-report 
    paster initdb --config=$CKAN_INI
    cd -

Populate with test data (**unless** you're installing a production database):

    paster --plugin=ckanext-dgu create-test-data --config=$CKAN_INI
    paster --plugin=ckan search-index rebuild --config=$CKAN_INI

Give yourself a CKAN user for debug:

    paster --plugin=ckan user remove admin --config=$CKAN_INI
    paster --plugin=ckan user add admin password=pass --config=$CKAN_INI
    paster --plugin=ckan sysadmin add admin --config=$CKAN_INI
