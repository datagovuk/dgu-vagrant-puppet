#!/bin/bash

# SOURCE: https://github.com/purple52/librarian-puppet-vagrant

# Directory in which librarian-puppet should manage its modules directory
PUPPET_DIR=/etc/puppet/

# NB: librarian-puppet might need git installed. If it is not already installed
# in your basebox, this will manually install it at this point using apt or yum

$(which git > /dev/null 2>&1)
FOUND_GIT=$?
if [ "$FOUND_GIT" -ne '0' ]; then
  echo 'Attempting to install git.'
  $(which apt-get > /dev/null 2>&1)
  FOUND_APT=$?
  $(which yum > /dev/null 2>&1)
  FOUND_YUM=$?

  if [ "${FOUND_YUM}" -eq '0' ]; then
    yum -q -y makecache
    yum -q -y install git
    echo 'git installed.'
  elif [ "${FOUND_APT}" -eq '0' ]; then
    apt-get -q -y update
    apt-get -q -y install git
    echo 'git installed.'
  else
    echo 'No package installer available. You may need to install git manually.'
  fi
else
  echo 'git found.'
fi

# Install newer Ruby version
# (Vagrant comes bundled with ruby 1.8.7 which is too old for librarian-puppet to access a https server that uses SNI - https://forge.puppetlabs.com)
$(which ruby | grep vagrant_ruby > /dev/null 2>&1)
FOUND_ACCEPTABLE_RUBY=$?
if [ "$FOUND_ACCEPTABLE_RUBY" -ne '1' ]; then
  echo 'Attempting to install ruby.'
  git clone https://github.com/rbenv/rbenv.git ~/.rbenv
  echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
  echo 'eval "$(rbenv init -)"' >> ~/.bashrc
  cd
  exec $SHELL
  echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bashrc
  exec $SHELL
  rbenv install 2.3.1
  rbenv global 2.3.1
else
  echo 'ruby found.'
fi
echo $PATH
which ruby
ruby --version

mkdir -p $PUPPET_DIR
cp /vagrant/puppet/Puppetfile $PUPPET_DIR

if [ "$(gem search -i librarian-puppet)" = "false" ]; then
  gem install librarian-puppet -v 1.0.3
  cd $PUPPET_DIR && librarian-puppet install --clean
else
  cd $PUPPET_DIR && librarian-puppet update --verbose
fi

