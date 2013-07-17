#
# Based on python_puppet's class python::pip.
# Modified to allow us to override the "unless" parameter with arbitrary bash commands.
# 
define dgu_ckan::python_package (
  $ensure      = present,
  $virtualenv  = 'system',
  $url         = false,
  $owner       = 'root',
  $proxy       = false,
  $environment = [],
  $unless      = false,
) {

  # Parameter validation
  if ! $virtualenv {
    fail('python::pip: virtualenv parameter must not be empty')
  }

  if $virtualenv == 'system' and $owner != 'root' {
    fail('python::pip: root user must be used when virtualenv is system')
  }

  $cwd = $virtualenv ? {
    'system' => '/',
    default  => "${virtualenv}",
  }

  $pip_env = $virtualenv ? {
    'system' => 'pip',
    default  => "${virtualenv}/bin/pip",
  }

  $proxy_flag = $proxy ? {
    false    => '',
    default  => "--proxy=${proxy}",
  }

  $unless_cmd = $unless ? {
    false => '/bin/true',
    default => $unless, 
  }

  $source = $url ? {
    false   => $name,
    default => "${url}",
  }

  case $ensure {
    present: {
      exec { "pip_install_${name}":
        command     => "$pip_env --log-file ${cwd}/pip.log install ${proxy_flag} ${source}",
        unless      => $unless_cmd,
        user        => $owner,
        environment => $environment,
      }
    }

    default: {
      exec { "pip_uninstall_${name}":
        command     => "echo y | $pip_env uninstall ${proxy_flag} ${name}",
        onlyif      => $unless_cmd,
        user        => $owner,
        environment => $environment,
      }
    }
  }
}
