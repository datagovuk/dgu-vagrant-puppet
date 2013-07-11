file { '/etc/motd':
  content => "Welcome to your Vagrant-built virtual machine!
              Managed by Puppet.
              $motd\n"
}

class base {
  file { '/home/vagrant/.bashrc':
     ensure => 'link',
     target => '/vagrant/.bashrc',
  }
  package { "screen":
    ensure => "installed"
  }
  package { "vim":
    ensure => "installed"
  }
  package { "pv":
    ensure => "installed"
  }
}

class frontend {
  class {apache:
    default_vhost => false,
    mpm_module => 'prefork',
  }
}

class frontend_ckan {
  include base
  include frontend
  include apache::mod::php
  apache::vhost {'localhost':
    port    => 80,
    docroot => '/var/www/',
    options => 'Indexes MultiViews',
  }
}

include frontend_ckan

