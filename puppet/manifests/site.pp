Exec {
  path => "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/opt/vagrant_ruby/bin",
}
node default {
  user { "vagrant":
    groups => ["www-data"],
  }

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
  package { "unzip":
    ensure => "installed"
  }
}
node /^ckan/ inherits default {
  include dgu_ckan
}
node /^drupal/ inherits default {
}

