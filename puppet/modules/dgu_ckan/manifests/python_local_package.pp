# Wrapper resource (for macro purposes)
define dgu_ckan::python_local_package (
  $virtualenv = 'system',
  $pip_freeze = '',
  $owner      = 'root'
) { 
  dgu_ckan::python_package { "pip-$name":
    virtualenv  => $virtualenv,
    url         => "-e /vagrant/src/${name}",
    unless      => "/bin/grep -i \"${name}\" $pip_freeze",
    owner       => $owner,
  }
}
