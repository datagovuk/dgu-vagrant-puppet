define ckan::virtualenv_package (
  $ensure = present, 
  $owner,
  $virtualenv_root,
  $pip_freeze_cache,
) {

  case $ensure {
    present: {
      exec { "pip_install_${name}":
        command   => "${virtualenv_root}/bin/pip install --log-file ${virtualenv_root}/pip.log ${name}",
        user      => $owner,
        logoutput => "on_failure",
        unless    => "${virtualenv_root}/bin/pip freeze | grep -ic ${name}",
      }
    }

    default: {
      exec { "pip_uninstall_${name}":
        command     => "/bin/echo y | ${virtualenv_root}/bin/pip uninstall ${name}",
        user        => $owner,
        logoutput   => "on_failure",
        onlyif      => "${virtualenv_root}/bin/pip freeze | grep -ic ${name}",
      }
    }
  }
}
