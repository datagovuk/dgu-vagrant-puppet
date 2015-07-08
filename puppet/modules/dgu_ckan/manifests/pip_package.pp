# Install a Pip package inside CKAN's VirtualEnv.
# Unless that package appears in the output of "pip_freeze".
# Uses custom Facter facts:
#   $ckan_virtualenv
#   $ckan_pip_freeze
define dgu_ckan::pip_package ($ensure = present, $owner, $local) {
  if $local {
    $url = "-e /src/${name}"
    $grep = "${name}@"
  } else {
    $url = $name
    $grep = $name
  }

  case $ensure {
    present: {
      if !($grep in $ckan_pip_freeze) {
        exec { "pip_install_${name}":
          command     => "${ckan_virtualenv}/bin/pip install --no-index --find-links=file:///vagrant/pypi --log-file ${ckan_virtualenv}/pip.log ${url}",
          user        => $owner,
          logoutput   => "on_failure",
          environment => ["XDG_CACHE_HOME=/home/co/.cache"],
        }
      }
    }

    default: {
      if ($grep in $ckan_pip_freeze) {
        exec { "pip_uninstall_${name}":
          command     => "/bin/echo y | ${ckan_virtualenv}/bin/pip uninstall ${name}",
          user        => $owner,
          logoutput   => "on_failure",
        }
      }
    }
  }
}
