# Install a Pip package inside CKAN's VirtualEnv.
# Unless that package appears in the output of "pip_freeze".
# Uses custom Facter facts:
#   $ckan_virtualenv
#   $ckan_pip_freeze
define dgu_ckan::pip_package ($ensure = present, $owner, $local) {
  if $local {
    $url = "-e /vagrant/src/${name}"
    $grep = "${name}@"
  } else {
    $url = $name
    $grep = $name
  }

  case $ensure {
    present: {
      if !($grep in $ckan_pip_freeze) {
        exec { "pip_install_${name}":
          command     => "${ckan_virtualenv}/bin/pip --log-file ${ckan_virtualenv}/pip.log install ${url}",
          user        => $owner,
        }
      }
    }

    default: {
      if ($grep in $ckan_pip_freeze) {
        exec { "pip_uninstall_${name}":
          command     => "/bin/echo y | ${ckan_virtualenv}/bin/pip uninstall ${name}",
          user        => $owner,
        }
      }
    }
  }
}
