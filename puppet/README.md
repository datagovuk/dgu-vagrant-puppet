# Datagovuk Puppet Master

## Installation

Get a stable version of puppet

    sudo apt-get update
    sudo apt-get install sudo apt-get install puppet=2.7.11-1ubuntu2.4

Overwrite /etc/puppet with this repo

    git clone $THIS_REPO
    sudo mv /etc/puppet{,.old}
    sudo ln -s $THIS_REPO/puppet /etc/

## Start server

Start the puppet master.

    sudo puppet master --mkusers

Or for interactive, debug, local use:

    sudo puppet master --mkusers --verbose --no-daemonize

## Updating clients

Create a hostname alias for the puppet master.

    # /etc/hosts
    $PUPPET_MASTER_IP puppet

Configure the agent to use the puppet master.

    # /etc/puppet/puppet.conf
    [agent]
    server = puppet
    
#### Example uses

Update this client immediately.

    sudo puppet agent --test

Update this client immediately, installing CKAN.

    export FACTER_CKAN=true
    sudo -E puppet agent --test

Update this client immediately, installing CKAN and Drupal.

    export FACTER_CKAN=true
    export FACTER_DRUPAL=true
    sudo -E puppet agent --test

Run a persistent background daemon, fetching the latest configuration every three minutes.

    # /etc/puppet/puppet.conf
    [agent]
    runinterval=180

    # /etc/default/puppet
    START=yes

    sudo /etc/init.d/puppet start

