# Install a Pip package inside CKAN's VirtualEnv.
# Unless that package appears in the output of "pip_freeze".
define dgu_ckan::pip_package ($ensure = present, $virtualenv, $pip_freeze, $owner, $local) {
  if $local {
    $url = "-e /vagrant/src/${name}"
    $grep_for = "${name}@"
  } else {
    $url = $name
    $grep_for = "^${name}\$"
  }

  case $ensure {
    present: {
      exec { "pip_install_${name}":
        command     => "${virtualenv}/bin/pip --log-file ${virtualenv}/pip.log install ${url}",
        unless      => "/bin/grep -i \"${grep_for}\" $pip_freeze",
        user        => $owner,
      }
    }

    default: {
      exec { "pip_uninstall_${name}":
        command     => "/bin/echo y | ${virtualenv}/bin/pip uninstall ${name}",
        onlyif      => "/bin/grep -i \"${grep_for}\" $pip_freeze",
        user        => $owner,
      }
    }
  }
}
