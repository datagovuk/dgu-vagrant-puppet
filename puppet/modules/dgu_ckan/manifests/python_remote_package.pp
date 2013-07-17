# Wrapper resource (for macro purposes)
define dgu_ckan::python_remote_package (
  $virtualenv = 'system',
  $pip_freeze = '',
  $owner      = 'root'
) { 
  dgu_ckan::python_package { "pip-$name": 
    virtualenv  => $virtualenv,
    url         => $name,
    unless      => "/bin/grep -i \"${name}\" $pip_freeze",
    owner       => $owner,
  }
}
