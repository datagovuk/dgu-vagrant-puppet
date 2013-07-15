# Keys

    ssh_authorized_key { "Richard's VM":
        ensure => present,
        key => "AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ",
        type => "ssh-rsa",
        user => "rcrowley",
    }

# Users

    sudo usermod -a -G www-data $USER

# Filesystem

    # CKAN temp folders 
    FOLDER_DATA=/home/$USER/ckan_data
    FOLDER_SSTORE=/home/$USER/ckan_sstore
    CKAN_INI=/home/$USER/ckan.ini
    mkdir -p {$FOLDER_DATA,$FOLDER_SSTORE}
    chmod g+w {$FOLDER_DATA,$FOLDER_SSTORE}
    sudo chgrp www-data {$FOLDER_DATA,$FOLDER_SSTORE}

    # Generate CKAN.ini file
    /vagrant/scripts/create_ckan_files.sh $FOLDER_DATA $FOLDER_SSTORE

    # CKAN logging
    sudo mkdir -p /var/log/ckan
    sudo touch /var/log/ckan/ckan.log
    sudo chown -R $USER /var/log/ckan
    sudo chmod -R g+w /var/log/ckan
    sudo chgrp -R www-data /var/log/ckan

# Packages

### Defunct?

    #subversion \
    #mercurial \
    #build-essential  \

### General

    daemon \
    libxslt1-dev  \
    libapache2-mod-wsgi \

# Python

      pip install -e /vagrant/src/ckan
      pip install -e /vagrant/src/ckanext-dgu
      pip install -e /vagrant/src/ckanext-os
      pip install -e /vagrant/src/ckanext-qa
      pip install -e /vagrant/src/ckanext-spatial
      pip install -e /vagrant/src/ckanext-harvest
      pip install -e /vagrant/src/ckanext-archiver
      pip install -e /vagrant/src/ckanext-ga-report
      pip install -e /vagrant/src/ckanext-datapreview

# PostgreSQL

    libpq-dev  \
    postgresql  \
    postgresql-contrib \
    postgresql-9.1-postgis \

    .pgpasswd creates postgresql password

    postgres user "vagrant" exists. **Superuser**
    Create user dgu: psql -d postgres -c "create user dgu nocreatedb nocreateuser password '`cat .pgpasswd`';"

    postgres template_postgis exists.
      sudo -u postgres createdb template_postgis
      #sudo -u postgres createlang -d template_postgis plpgsql;
      sudo -u postgres psql -d template_postgis -c "CREATE EXTENSION hstore;"
      sudo -u postgres psql -d template_postgis -f /usr/share/postgresql/9.1/contrib/postgis-1.5/postgis.sql
      sudo -u postgres psql -d template_postgis -f /usr/share/postgresql/9.1/contrib/postgis-1.5/spatial_ref_sys.sql
      sudo -u postgres psql -d template_postgis -c "select postgis_lib_version();" 
      sudo -u postgres psql -d template_postgis -c "GRANT ALL ON geometry_columns TO PUBLIC;"
      sudo -u postgres psql -d template_postgis -c "GRANT ALL ON spatial_ref_sys TO PUBLIC;"
      sudo -u postgres psql -d template_postgis -c "GRANT ALL ON geography_columns TO PUBLIC;"

    # Generate CKAN DB
      createdb -O dgu ckan --template template_postgis
      paster --plugin=ckan db init --config=$CKAN_INI 
      cd /vagrant/src/ckanext-ga-report 
      paster initdb --config=$CKAN_INI
      cd -
      paster --plugin=ckanext-dgu create-test-data --config=$CKAN_INI
      paster --plugin=ckan search-index rebuild --config=$CKAN_INI
      paster --plugin=ckan user remove admin --config=$CKAN_INI
      paster --plugin=ckan user add admin password=pass --config=$CKAN_INI
      paster --plugin=ckan sysadmin add admin --config=$CKAN_INI


# JDK

    sudo apt get openjdk-6-jre-headless ?

# Apache

    # Create CKAN configuration based on /etc/apache/ckan

# Solr

    Install Solr 3.3.0 ?
    # Generate SOLR core
    sudo mv /usr/local/solr/example/solr/conf/schema.xml{,.orig}
    sudo ln -fs /vagrant/src/ckanext-dgu/config/solr/schema-1.4-dgu.xml /usr/local/solr/example/solr/conf/schema.xml

