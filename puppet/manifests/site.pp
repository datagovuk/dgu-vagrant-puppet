Exec {
  # Set defaults for execution of commands
  path => "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/opt/ruby/bin",
}
group {"co":
  ensure => present,
}
file {"/home/co":
  require => [ User["co"], Group["co"] ],
  ensure  => directory,
  owner   => "co",
  group   => "co",
}
user { "co":
  require    => Group["co"],
  ensure     => present,
  managehome => true,
  gid        => "co",
  shell      => "/bin/bash",
  home       => "/home/co",
  groups     => ["sudo","adm","www-data"],
  password   => '$6$0GdtHw6P$Zd7KquceLtpQn5CWtN24yA6mGy0XYgrPz7XHe4PSnbSfYHutAW3RRXQWMgw3Q56F5FzpXzuZ6R9mBpNF/58Gb.',
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

include dgu_ckan

