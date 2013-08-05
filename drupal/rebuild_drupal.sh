#!/usr/bin/env bash

# Exit if anything goes wrong
set -e 

sudo ln -fs /vagrant/etc/apache2/sites-available/drupal /etc/apache2/sites-available/
sudo a2ensite drupal

# Download source code & drupal version
DRUPAL_TARGET=/home/vagrant/drupal

if [ -e $DRUPAL_TARGET ] ; then
  echo "Error: $DRUPAL_TARGET already exists." >&2
  exit 1
fi

# Get rid of previous repo and build if exist
drush make --working-copy --no-gitinfofile /vagrant/scripts/distro.make $DRUPAL_TARGET
cd $DRUPAL_TARGET

# Add Drupal6 files directory location (required for migration)
# It assumes that production files directory is rcync'ed to /var/www/shared/
echo "\$conf['drupal6files'] = '/var/www/shared/';"  >> $DRUPAL_TARGET/sites/default/default.settings.php;

# Configure MySQL
mysql -e "CREATE USER 'co'@'localhost' IDENTIFIED BY 'pass';" -u root -ppass
mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'co'@'localhost';" -u root -ppass
mysql -e "GRANT DROP ON *.* TO 'co'@'localhost';" -u root -ppass

# Install Drupal
drush si dgu -y --site-name="data.gov.uk" --account-name=admin --account-pass=pass --db-url=mysql://co:pass@localhost/drupal;

# Add setting for Drupal6 production database dump (required for migration)
chmod 644 $DRUPAL_TARGET/sites/default/settings.php
echo "\$databases['d6source']['default'] = array('driver' => 'mysql', 'database' => 'drupald6', 'username' => 'co', 'password' => 'pass', 'host' => 'localhost', 'prefix' => '',);" >> $DRUPAL_TARGET/sites/default/settings.php;
chmod 444 $DRUPAL_TARGET/sites/default/settings.php

chgrp www-data $DRUPAL_TARGET/sites/default/files
chmod g+w $DRUPAL_TARGET/sites/default/files

# Enable features
drush features-list | grep DGU | sed 's/.*dgu/dgu/g' | xargs drush en -y
# Revert features
drush fra -y;
drush cc all;
drush fra -y;

# TODO install themes

# Fix the autoload.php errors
#sudo apt-get install -y curl
#curl -sS https://getcomposer.org/installer | php -- --install-dir=$DRUPAL_TARGET/profiles/dgu/libraries;
#cd $DRUPAL_TARGET;
#drush composer-rebuild;
#cd $DRUPAL_TARGET/sites/default/files/composer;
#$DRUPAL_TARGET/profiles/dgu/libraries/composer.phar install;
# alternative:
# [18/06/2013 17:05:43] Pawel Ratajczak: "drush dis -y ckan" should work

sudo service apache2 restart
