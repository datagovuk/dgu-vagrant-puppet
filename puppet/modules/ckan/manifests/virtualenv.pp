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

  $ckan_requirements = [
    "Genshi==0.6",
    'Jinja2==2.7',
    "Pylons==0.9.7",
    "WebTest==1.4.3",
    "apachemiddleware==0.1.1",
    "babel==0.9.6",
    "docutils==0.8.1",
    "fanstatic==0.12",
    "formalchemy==1.4.2",
    "markupsafe==0.15",
    'nose==1.3.0',
    "ofs==0.4.1",
    "pairtree==0.7.1-T",
    "paste==1.7.5.1",
    "psycopg2==2.4.5",
    'python-dateutil==1.5',
    'pyutilib.component.core==4.6',
    'repoze.who-friendlyform==1.0.8',
    'repoze.who.plugins.openid==0.5.3',
    'repoze.who==1.0.19',
    'requests==1.1',
    "routes==1.13",
    "solrpy==0.9.5",
    "sphinx>=1.1",
    "sqlalchemy-migrate==0.7.2",
    "sqlalchemy==0.7.8",
    "tempita==0.5.1",
    "vdm==0.11",
    "webhelpers==1.3",
    "webob==1.0.8",
    "zope.interface==4.0.1",
  ]
  ckan::virtualenv_package { $ckan_requirements:
    ensure            => present,
    owner            => $virtualenv_owner,
    virtualenv_root  => $virtualenv_root,
    pip_freeze_cache => '',
  }

}
