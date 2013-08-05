# Setup

Install Vagrant. Switch to this directory and launch a fully provisioned Virtual Machine:

    vagrant up

To provision an existing machine, execute:

    sudo hostname ckan
    sudo vim /etc/hosts
    # ^ add "127.0.0.1  ckan" to hosts...
    sudo puppet apply $THIS_REPO/puppet/manifests/site.pp

# CKAN Database setup

Populate with test data (**unless** you're installing a production database):

    paster --plugin=ckanext-dgu create-test-data --config=$CKAN_INI
    paster --plugin=ckan search-index rebuild --config=$CKAN_INI

Give yourself a CKAN user for debug:

    paster --plugin=ckan user remove admin --config=$CKAN_INI
    paster --plugin=ckan user add admin password=pass --config=$CKAN_INI
    paster --plugin=ckan sysadmin add admin --config=$CKAN_INI
