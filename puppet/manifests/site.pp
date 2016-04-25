Exec {
  # Set defaults for execution of commands
  path => "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/opt/ruby/bin",
}
group {"puppet":
  ensure => present,
}
group {"co":
  ensure => present,
}
class { 'sudo':
  purge               => false,
  config_file_replace => false,
}
sudo::conf { 'sudo':
  priority => 10,
  content  => "%sudo ALL=(ALL) NOPASSWD: ALL",
}
file {"/home/co":
  require => [ User["co"], Group["co"] ],
  ensure  => directory,
  owner   => "co",
  group   => "co",
}
user { "co":
  require    => [Group["co"],
                 Sudo::Conf["sudo"]],
  ensure     => present,
  managehome => true,
  uid        => "510",
  gid        => "co",
  shell      => "/bin/bash",
  home       => "/home/co",
  groups     => ["sudo","adm","www-data"],
}

file { '/etc/fqdn':
  content => $::fqdn
}
file { '/etc/motd':
  content => "Welcome to your Puppet-built virtual machine!
              $motd\n"
}
file { '/home/co/.bashrc':
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
package { "curl":
  ensure => "installed"
}

# ---------
# Drupal bits
# ---------
package { "mysql-server-5.5":
  ensure => "installed"
}
package { "php5-gd":
  ensure => "installed"
}
package { "php5-mysql":
  ensure => "installed"
}
package { "php5-curl":
  ensure => "installed"
}
file {'/var/www/api_users':
  ensure => file,
  content => template('dgu_ckan/api_users.erb'),
  owner   => "co",
  group   => "www-data",
}

include dgu_ckan

