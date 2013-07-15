node default {
  file { '/etc/fqdn':
    content => $::fqdn
  }
  file { '/etc/motd':
    content => "Welcome to your Vagrant-built virtual machine!
                Managed by Puppet.
                $motd\n"
  }
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
node /^ckan/ inherits default {
  file { "/etc/nodetype":
    content => "ckan",
  }
  class { "frontend_ckan":

  }
}
node /^drupal/ inherits default {
  file { "/etc/nodetype":
    content => "drupal",
  }
}

