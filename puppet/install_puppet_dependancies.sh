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
# ruby 2.3.1 is latest, but 2.2 is the latest puppet supports
if [ "$FOUND_ACCEPTABLE_RUBY" -ne '1' ]; then
  if [ -a $HOME/.rbenv/bin ]; then
    echo 'rbenv installed but not activated - probably because we are in the vagrant shell'
    export PATH="$HOME/.rbenv/bin:$PATH"
    eval "$(rbenv init -)"
    export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"
    export RBENV_VERSION="2.2.5"
    echo 'rbenv activated'
  else
    echo 'Attempting to install ruby.'
    git clone https://github.com/rbenv/rbenv.git ~/.rbenv
    echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
    echo 'eval "$(rbenv init -)"' >> ~/.bashrc
    echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bashrc
    echo 'export RBENV_VERSION="2.2.5"' >> ~/.bashrc
    # run those same commands now (when run in puppet provision, it doesn't like us running a new shell)
    export PATH="$HOME/.rbenv/bin:$PATH"
    eval "$(rbenv init -)"
    export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"
    export RBENV_VERSION="2.2.5"
    # install 'ruby build' - it provides the 'rbenv install' command
    git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
    rbenv install 2.2.5
    rbenv global 2.2.5
  fi
else
  echo 'ruby found.'
fi
which ruby
ruby --version

# Install puppet gem
# (Vagrant's bundled ruby had it, but the new ruby needs it)
gem list | grep -q puppet
FOUND_PUPPET=$?
if [ "$FOUND_PUPPET" -ne '0' ]; then
  echo Installing puppet gem
  gem install puppet -v 3.7
else
  echo Found puppet gem
fi

# Install syck, used by safe_yaml (used by puppet) and not included with ruby 1.9+
gem list | grep -q syck
FOUND_GEM=$?
if [ "$FOUND_GEM" -ne '0' ]; then
  echo Installing syck gem
  gem install syck
else
  echo Found syck gem
fi

# Patch puppet's safe_yaml to help it find the syck that we installed. This was from a tip here:
# https://tickets.puppetlabs.com/browse/PUP-3796?focusedCommentId=131681&page=com.atlassian.jira.plugin.system.issuetabpanels:comment-tabpanel#comment-131681
PATCH_FILENAME=/root/.rbenv/versions/2.2.5/lib/ruby/gems/2.2.0/gems/puppet-3.7.0/lib/puppet/vendor/safe_yaml/lib/safe_yaml/syck_node_monkeypatch.rb
grep -q 'require "syck"' $PATCH_FILENAME
UNPATCHED=$?
if [ -f "$PATCH_FILENAME" ] && [ $UNPATCHED -eq '0' ]; then
  echo 'Found patch for syck'
elif [ -a $PATCH_FILENAME ]; then
  echo "Patching $PATCH_FILENAME"
  sed -i '42 i\  require "syck"' $PATCH_FILENAME
else
  echo "Cannot find $PATCH_FILENAME to patch"
  exit 1
fi

mkdir -p $PUPPET_DIR
cp /vagrant/puppet/Puppetfile $PUPPET_DIR

if [ "$(gem search -i librarian-puppet)" = "false" ]; then
  gem install librarian-puppet -v 2.2.3
  cd $PUPPET_DIR && librarian-puppet install --clean
else
  cd $PUPPET_DIR && librarian-puppet update --verbose
fi

