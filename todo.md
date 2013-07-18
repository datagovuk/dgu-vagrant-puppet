
# Java

    We use a hardcoded path to the JVM, which is rubbish, use ${::architecture}

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

# Solr

    sudo apt get openjdk-6-jre-headless ?
    Install Solr 3.3.0 ?
    # Generate SOLR core
    sudo mv /usr/local/solr/example/solr/conf/schema.xml{,.orig}
    sudo ln -fs /vagrant/src/ckanext-dgu/config/solr/schema-1.4-dgu.xml /usr/local/solr/example/solr/conf/schema.xml

