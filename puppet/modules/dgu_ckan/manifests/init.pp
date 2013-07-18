class dgu_ckan {
  # Uses custom fact: 
  #  $ckan_virtualenv

  class {  'apache':
    default_vhost => false,
    mpm_module => 'prefork',
  }
  apache::vhost {'localhost':
    port    => 80,
    docroot => '/var/www/',
    options => 'Indexes MultiViews',
  }
  class { 'python':
    version    => 'system',
    dev        => true,
    virtualenv => true,
    pip        => true,
  }

  $python_requirements = [
    'libxslt1-dev',
    'libpq-dev',
    'libapache2-mod-wsgi',
    'python-psycopg2',
    'python-pastescript',
  ]
  package { $python_requirements:
    ensure => installed,
    before => Python::VirtualEnv[$ckan_virtualenv],
  }
  python::virtualenv { $ckan_virtualenv:
    ensure => present,
    version => 'system',
    owner => 'vagrant',
    group => 'vagrant',
  }

  # Pip install everything
  dgu_ckan::pip_package { [
    'Babel==0.9.4',
    'Beaker==1.6.3',
    'ConcurrentLogHandler==0.8.4',
    'Flask==0.8',
    'FormAlchemy==1.4.1',
    'FormEncode==1.2.4',
    'Genshi==0.6',
    'GeoAlchemy==0.7.2',
    'Jinja2==2.7',
    'Mako==0.8.1',
    'MarkupSafe==0.9.2',
    'OWSLib==0.7.2',
    'Pairtree==0.7.1-T',
    'Paste==1.7.2',
    'PasteDeploy==1.5.0',
    'PasteScript==1.7.5',
    'Pygments==1.6',
    'Pylons==0.9.7',
    'Routes==1.11',
    'SQLAlchemy==0.7.3',
    'Shapely==1.2.17',
    'Tempita==0.4',
    'WebError==0.10.3',
    'WebHelpers==1.2',
    'WebOb==1.0.8',
    'WebTest==1.2',
    'Werkzeug==0.8.3',
    'amqplib==1.0.2',
    'anyjson==0.3.3',
    'apachemiddleware==0.1.1',
    'autoneg==0.5',
    'carrot==0.10.1',
    'celery==2.4.2',
    'chardet==2.1.1',
    'ckanclient==0.10',
    'decorator==3.3.2',
    'flup==1.0.2',
    'gdata==2.0.17',
    'google-api-python-client==1.1',
    'httplib2==0.8',
    'json-table-schema==0.1',
    'kombu==2.1.3',
    'kombu-sqlalchemy==1.1.0',
    'lxml==2.2.4',
    'messytables==0.10.0',
    'nose==1.3.0',
    'ofs==0.4.1',
    'openpyxl==1.5.7',
    'psycopg2==2.4.2',
    'python-dateutil==1.5',
    'python-gflags==2.0',
    'python-magic==0.4.3',
    'python-openid==2.2.5',
    'pytz==2012j',
    'pyutilib.component.core==4.6',
    'repoze.who==1.0.19',
    'repoze.who-friendlyform==1.0.8',
    'repoze.who.plugins.openid==0.5.3',
    'requests==0.14.0',
    'simplejson==2.6.2',
    'solrpy==0.9.4',
    'sqlalchemy-migrate==0.7.1',
    'vdm==0.11',
    'xlrd==0.9.2',
    'zope.interface==3.5.3',
  ]: 
    require => Python::Virtualenv[$ckan_virtualenv],
    ensure     => present,
    owner      => 'vagrant',
    local      => false,
  }
  dgu_ckan::pip_package { [
    'ckan',
    'ckanext-dgu',
    'ckanext-os',
    'ckanext-qa',
    'ckanext-spatial',
    'ckanext-harvest',
    'ckanext-archiver',
    'ckanext-ga-report',
    'ckanext-datapreview',
  ]: 
    require => Python::Virtualenv[$ckan_virtualenv],
    ensure  => present,
    owner   => 'vagrant',
    local   => true,
  }



  # ------------
  # CKAN folders
  # ------------
  $pg_password = "pass"
  $ckan_root = "/var/ckan"
  $ckan_ini = "${ckan_root}/ckan.ini"
  $ckan_who_ini = "${ckan_root}/who.ini"
  $ckan_log_root = "/var/log/ckan"
  $ckan_log_file = "${ckan_log_root}/ckan.log"
  file {$ckan_log_file:
    ensure => "exists",
    owner  => "www-data",
    group  => "www-data",
    mode   => 0664,
  }
  file { [$ckan_log_root, $ckan_root, "${ckan_root}/data","${ckan_root}/sstore"]:
    ensure => "directory",
    owner  => "www-data",
    group  => "www-data",
    mode   => "0664",
  }
  file { $ckan_ini:
    content => template('dgu_ckan/ckan.ini.erb'),
    owner   => "www-data",
    group   => "www-data",
    mode    => "0664",
  }
  file { $ckan_who_ini:
    content => template('dgu_ckan/who.ini.erb'),
    owner   => "www-data",
    group   => "www-data",
    mode    => "0664",
  }


  # -----------
  # Postgres DB
  # -----------
  $pg_superuser_pass = 'pass'
  $ckan_db = 'ckan'
  $ckan_db_user = 'dgu'
  $ckan_db_pass = 'pass'
  $postgis_version = "9.1"

  class { "postgresql::server":
    config_hash => {
      'listen_addresses'           => '*',
      'postgres_password'          => $pg_superuser_pass,
    },
  }
  package {"postgresql-${postgis_version}-postgis":
    ensure => present,
    require => Class['postgresql::server'],
  }

  postgresql::role { "root":
    password_hash => postgresql_password("root",$pg_superuser_pass),
    createdb      => true,
    createrole    => true,
    login         => true,
    superuser     => true,
  }
  postgresql::role { $ckan_db_user:
    password_hash => postgresql_password($ckan_db_user,$ckan_db_pass),
    login         => true,
  }

  # if only puppetlabs/postgresql allowed me to specify a template...
  exec {"createdb ${ckan_db}":
    command => "createdb -O ${ckan_db_user} ckan --template template_postgis",
    unless  => "psql -l|grep ckan",
    path    => "/usr/bin:/bin",
    user    => postgres,
    require => [
      Exec["createdb postgis_template"],
      Postgresql::Role[$ckan_db_user],
      Class["postgresql::server"],
    ],
  }
  # Build template database
  file { "/tmp/create_postgis_template.sh":
    source => "puppet:///modules/dgu_ckan/create_postgis_template.sh",
    mode   => 0755,
  }
  exec {"createdb postgis_template":
  command => "/tmp/create_postgis_template.sh",
  unless  => "psql -l |grep template_postgis",
    path    => "/usr/bin:/bin",
    user    => root,
    require => [
      File["/tmp/create_postgis_template.sh"],
      Package["postgresql-${postgis_version}-postgis"],
      Postgresql::Role["root"],
    ]
  }




}
