class ckan::virtualenv(
  $virtualenv_root,
  $virtualenv_owner,
  $virtualenv_group,
) {
  class { 'python':
    version    => 'system',
    dev        => true,
    virtualenv => true,
    pip        => true,
  }
  $python_requirements = [
    'libxslt1-dev',
    'libpq-dev',
    'python-psycopg2',
    'python-pastescript',
  ]
  package { $python_requirements:
    ensure => installed,
    before => Python::VirtualEnv[$ckan_virtualenv],
  }
  python::virtualenv { $virtualenv_root:
    ensure => present,
    version => 'system',
    owner => $virtualenv_owner,
    group => $virtualenv_group,
  }
}
