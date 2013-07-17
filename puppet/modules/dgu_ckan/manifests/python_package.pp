#
# Based on python_puppet's class python::pip.
# Modified to allow us to override the "unless" parameter with arbitrary bash commands.
# 
define dgu_ckan::python_package (
  $ensure      = present,
  $owner       = 'root',
  $virtualenv,
  $url,
  $unless,
) {

  case $ensure {
    present: {
      exec { "pip_install_${name}":
        command     => "${virtualenv}/bin/pip --log-file ${virtualenv}/pip.log install ${url}",
        unless      => $unless
        user        => $owner,
      }
    }

    default: {
      exec { "pip_uninstall_${name}":
        command     => "echo y | ${virtualenv}/bin/pip uninstall ${name}",
        onlyif      => $unless
        user        => $owner,
      }
    }
  }
}
