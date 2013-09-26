## Puppet Master: Installation

See [../README.md](../README.md) first. Ensure puppet is installed. 

Overwrite `/etc/puppet` with this folder.

    git clone $THIS_REPO
    sudo mv /etc/puppet{,.old}
    sudo ln -s $THIS_REPO/puppet /etc/

Install vendor modules.

    sudo gem install librarian-puppet
    cd /etc/puppet
    sudo librarian-puppet install --verbose

Start the puppet master.

    sudo puppet master --mkusers

Or for interactive, debug, local use:

    sudo puppet master --mkusers --verbose --no-daemonize

---

#### Updating clients

Create a hostname alias for the puppet master.

    # /etc/hosts
    $PUPPET_MASTER_IP puppet

Configure the agent to use the puppet master.

    # /etc/puppet/puppet.conf
    [agent]
    server = puppet

**Example:** Update this client immediately.

    sudo puppet agent --test

**Example:** Update this client immediately, installing CKAN.

    export FACTER_CKAN=true
    sudo -E puppet agent --test

**Example:** Update this client immediately, installing CKAN and Drupal.

    export FACTER_CKAN=true
    export FACTER_DRUPAL=true
    sudo -E puppet agent --test

**Example:** Run a persistent background daemon, fetching the latest configuration every three minutes.

```
# /etc/puppet/puppet.conf
[agent]
runinterval=180
```
```
# /etc/default/puppet
START=yes
```
    sudo /etc/init.d/puppet start
