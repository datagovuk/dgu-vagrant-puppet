
# PostgreSQL

    # TODO required? `apt-get postgresql-contrib`

    # Generate CKAN DB
    paster --plugin=ckan db init --config=$CKAN_INI 
    cd /vagrant/src/ckanext-ga-report 
    paster initdb --config=$CKAN_INI
    cd -
    paster --plugin=ckanext-dgu create-test-data --config=$CKAN_INI
    paster --plugin=ckan search-index rebuild --config=$CKAN_INI
    paster --plugin=ckan user remove admin --config=$CKAN_INI
    paster --plugin=ckan user add admin password=pass --config=$CKAN_INI
    paster --plugin=ckan sysadmin add admin --config=$CKAN_INI


# Apache

    # Create CKAN configuration based on /etc/apache/ckan

