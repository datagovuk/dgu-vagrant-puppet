class datagovuk::common {
  # Set defaults for execution of commands
  Exec {
    path => "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/opt/ruby/bin",
  }
  File {
    owner => 'co',
    group => 'co',
  }

  # Base user
  # #########
  group {"co":
    ensure => present,
  }
  user { "co":
    require    => Group["co"],
    ensure     => present,
    managehome => true,
    gid        => "co",
    shell      => "/bin/bash",
    groups     => ["sudo","adm","www-data"],
    password   => '$6$0GdtHw6P$Zd7KquceLtpQn5CWtN24yA6mGy0XYgrPz7XHe4PSnbSfYHutAW3RRXQWMgw3Q56F5FzpXzuZ6R9mBpNF/58Gb.',
  }

  # Install a base set of packages
  # ##############################
  $useful_packages = [
    'screen',
    'vim',
    'pv',
    'git',
    'unzip']
  package { $useful_packages:
    ensure => "installed"
  }

  # Standard environment 
  # ####################
  file { '/home/co/.bashrc':
     ensure  => file,
     content => template('datagovuk/bashrc'),
  }
  file { '/home/co/.ssh':
    ensure => directory,
  }
  file { '/home/co/.ssh/authorized_keys':
    ensure  => file,
    content => template('datagovuk/authorized_keys'),
  }
  file { '/etc/sudoers':
    ensure  => file,
    mode    => 0440,
    content => template('datagovuk/sudoers'),
    owner   => root,
    group   => root,
  }
}
