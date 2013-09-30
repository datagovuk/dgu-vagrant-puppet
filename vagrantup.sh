#!/bin/sh

# Simple application of the README file to a fresh (precise64) Vagrant VM.
# You could work all this out if you read the README.

$(which puppet > /dev/null 2>&1)
FOUND_PUPPET=$?
$(which git > /dev/null 2>&1)
FOUND_GIT=$?
$(which librarian-puppet > /dev/null 2>&1)
FOUND_LIBRARIAN=$?
$(stat /etc/puppet/Puppetfile > /dev/null 2>&1)
FOUND_PUPPETFILE=$?

if [ "$FOUND_PUPPET" -ne '0' ]; then
  wget http://apt.puppetlabs.com/puppetlabs-release-precise.deb
  sudo dpkg -i puppetlabs-release-precise.deb
  sudo apt-get update
  sudo apt-get install -y puppet-common=2.7.23-1puppetlabs1 puppet=2.7.23-1puppetlabs1
fi

if [ "$FOUND_GIT" -ne '0' ]; then
  sudo apt-get install -y git
fi
if [ "$FOUND_LIBRARIAN" -ne '0' ]; then
  sudo gem librarian-puppet install
fi
if [ "$FOUND_PUPPETFILE" -ne '0' ]; then
  sudo mv /etc/puppet{,.old}
  sudo ln -s /vagrant/puppet /etc/
fi

cd /etc/puppet/
sudo librarian-puppet install --verbose

echo "Provisioning complete."
echo "Run a local puppet master:"
echo "  sudo puppet master --mkusers"
echo "Update /etc/hosts with the line:"
echo "  127.0.0.1 puppet"
echo "Run a puppet agent:"
echo "  sudo puppet agent --test"

