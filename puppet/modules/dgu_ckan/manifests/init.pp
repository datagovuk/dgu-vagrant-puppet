class dgu_ckan {

  file {'/home/co/.ssh/':
    ensure => directory,
    owner  => 'co',
    group  => 'co',
  }
  file {'/home/co/.ssh/authorized_keys':
    ensure => file,
    source => "puppet:///modules/dgu_ckan/authorized_keys",
    mode   => 0755,
    owner  => 'co',
    group  => 'co',
  }
  class { 'memcached':
      install_dev => true
  }

  # Uses custom fact:
  #  $ckan_virtualenv

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
  python::virtualenv { $ckan_virtualenv:
    ensure => present,
    version => 'system',
    owner => 'co',
    group => 'co',
  }

  # Pip install everything
  $pip_pkgs_remote = [
    'Babel==0.9.6',
    'Beaker==1.6.3',
    'ConcurrentLogHandler==0.8.4',
    'Flask==0.8',
    'FormAlchemy==1.4.2',
    'FormEncode==1.2.4',
    'Genshi==0.6',
    'GeoAlchemy==0.7.2',
    'Jinja2==2.7',
    'Mako==0.8.1',
    'MarkupSafe==0.15',
    'OWSLib==0.8.2',
    'Pairtree==0.7.1-T',
    'Paste==1.7.5.1',
    'PasteDeploy==1.5.0',
    'PasteScript==1.7.5',
    'Pygments==1.6',
    'Pylons==0.9.7',
    'PyMollom==0.1',
    'Routes==1.13',
    'SQLAlchemy==0.7.8',
    'Shapely==1.2.17',
    'Tempita==0.5.1',
    'WebError==0.10.3',
    'WebHelpers==1.3',
    'WebOb==1.0.8',
    'WebTest==1.4.3',
    'Werkzeug==0.8.3',
    'amqplib==1.0.2',
    'anyjson==0.3.3',
    'apachemiddleware==0.1.1',
    'autoneg==0.5',
    'carrot==0.10.1',
    'celery==2.4.2',
    'chardet==2.1.1',
    'ckanclient==0.10',
    'datautil==0.4',
    'decorator==3.3.2',
    'factory-boy==2.1.1',
    'fanstatic==0.12',
    'flup==1.0.2',
    'gdata==2.0.17',
    'google-api-python-client==1.1',
    'httplib2==0.8',
    'json-table-schema==0.1',
    'kombu==2.1.3',
    'kombu-sqlalchemy==1.1.0',
    'lxml==3.2.4',
    'messytables==0.10.0',
    'mock=1.0.1',
    'nltk==2.0.4',
    'nose==1.3.0',
    'ofs==0.4.1',
    'openpyxl==1.5.7',
    'psycopg2==2.4.5',
    'pylibmc',
    'python-dateutil==1.5',
    'python-gflags==2.0',
    'python-magic==0.4.3',
    'python-openid==2.2.5',
    'pytz==2012j',
    'pyutilib.component.core==4.6',
    'repoze.who==1.0.19',
    'repoze.who-friendlyform==1.0.8',
    'repoze.who.plugins.openid==0.5.3',
    'requests==1.1',
    'simplejson==2.6.2',
    'solrpy==0.9.5',
    'sqlalchemy-migrate==0.7.2',
    'unicodecsv==0.9.4',
    'vdm==0.11',
    'xlrd==0.9.2',
    'zope.interface==4.0.1',
    # from dev-requirements.txt
    'pep8==1.4.6',
  ]
  dgu_ckan::pip_package { $pip_pkgs_remote:
    require => Python::Virtualenv[$ckan_virtualenv],
    ensure     => present,
    owner      => 'co',
    local      => false,
  }
  $pip_pkgs_local = [
    'ckan',
    'ckanext-dgu',
    'ckanext-os',
    'ckanext-qa',
    'ckanext-spatial',
    'ckanext-harvest',
    'ckanext-archiver',
    'ckanext-ga-report',
    'ckanext-datapreview',
    'ckanext-importlib',
    'ckanext-hierarchy',
    'ckanext-report',
    'ckanext-dgu-local',
    'logreporter',
  ]
  dgu_ckan::pip_package { $pip_pkgs_local:
    require => [
        Python::Virtualenv[$ckan_virtualenv],
        Dgu_ckan::Pip_package[$pip_pkgs_remote],
    ],
    ensure  => present,
    owner   => 'co',
    local   => true,
  }
  # Not all Pip packages come with a global read permission
  exec {'setup_virtualenv_permissions':
    subscribe => [
      Dgu_ckan::Pip_package[$pip_pkgs_remote],
      Dgu_ckan::Pip_package[$pip_pkgs_local],
    ],
    command   => "chmod -R a+r $ckan_virtualenv/lib",
    user      => "root",
    path      => "/usr/bin:/bin:/usr/sbin",
  }
  notify { "virtualenv_ready":
    require => [
      Dgu_ckan::Pip_package[$pip_pkgs_remote],
      Dgu_ckan::Pip_package[$pip_pkgs_local],
    ],
    message => "All Pip packages are installed. VirtualEnv is ready.",
  }


  # ------------
  # CKAN folders
  # ------------
  $ckan_root = "/var/ckan"
  $ckan_ini = "${ckan_root}/ckan.ini"
  $ckan_db_user = 'dgu'
  $ckan_db_name = 'ckan'
  $ckan_test_db_user = 'ckan_default' # because it is in test-core.ini
  $ckan_test_db_name = 'ckan_test'
  $ckan_db_pass = 'pass'
  $ckan_who_ini = "${ckan_root}/who.ini"
  $ckan_log_root = "/var/log/ckan"
  $ckan_log_file = "${ckan_log_root}/ckan.log"
  file {$ckan_log_file:
    ensure => file,
    owner  => "www-data",
    group  => "www-data",
    mode   => 664,
  }
  file { [$ckan_log_root, $ckan_root, "${ckan_root}/data","${ckan_root}/sstore"]:
    ensure => directory,
    owner  => "www-data",
    group  => "www-data",
    mode   => 664,
  }
  define ckan_config_file(
    $path = $title,
    $ckan_db,
    $ckan_site_port = 80,
  ) {
    file { $path :
      ensure  => file,
      content => template('dgu_ckan/ckan.ini.erb'),
      owner   => "www-data",
      group   => "www-data",
      mode    => 664,
    }
  }
  ckan_config_file { 'ckan_ini_file':
    path => $ckan_ini,
    ckan_db => "$ckan_db_name",
  }
  file { '/vagrant/src/ckan/ckan.ini':
   ensure => 'link',
   target => $ckan_ini,
  }
  file { $ckan_who_ini:
    ensure  => file,
    content => template('dgu_ckan/who.ini.erb'),
    owner   => "www-data",
    group   => "www-data",
    mode    => 664,
  }
  notify {'ckan_fs_ready':
    require => [
      File[$ckan_log_file],
      File["${ckan_root}/data"],
      File["${ckan_root}/sstore"],
      File[$ckan_ini],
      File[$ckan_who_ini],
    ],
    message => "CKAN's filesystem is ready.",
  }


  # -----------
  # Postgres DB
  # -----------
  $pg_superuser_pass = 'pass'
  $postgis_version = "9.1"

  class { "postgresql::server":
    listen_addresses  => '*',
    postgres_password => $pg_superuser_pass,
  }
  package {"postgresql-${postgis_version}-postgis":
    ensure => present,
    require => Class['postgresql::server'],
  }

  postgresql::server::role { "co":
    password_hash => postgresql_password("co",$pg_superuser_pass),
    createdb      => true,
    createrole    => true,
    login         => true,
    superuser     => true,
    require       => Class["postgresql::server"],
  }
  postgresql::server::role { $ckan_db_user:
    password_hash => postgresql_password($ckan_db_user,$ckan_db_pass),
    login         => true,
    require       => Class["postgresql::server"],
  }
  postgresql::server::role { $ckan_test_db_user:
    password_hash => postgresql_password($ckan_test_db_user,$ckan_db_pass),
    login         => true,
    require       => Class["postgresql::server"],
  }

  # if only puppetlabs/postgresql allowed me to specify a template...
  exec {"createdb ${ckan_db_name}":
    command   => "createdb -O ${ckan_db_user} ${ckan_db_name} --template template_postgis",
    unless    => "psql -l|grep '${ckan_db_name}\s'",
    path      => "/usr/bin:/bin",
    user      => postgres,
    logoutput => true,
    require   => [
      Exec["createdb postgis_template"],
      Postgresql::Server::Role[$ckan_db_user],
      Class["postgresql::server"],
    ],
  }
  # The testing process deletes all tables, which doesn't work if there are the Postgis
  # ones there owned by the co user and no deletable. Reconsider this when testing
  # ckanext-spatial.
  exec {"createdb ${ckan_test_db_name}":
    command   => "createdb -O ${ckan_test_db_user} ${ckan_test_db_name} --template template_utf8",
    unless    => "psql -l | grep \" ${ckan_test_db_name} \"",
    path      => "/usr/bin:/bin",
    user      => postgres,
    logoutput => true,
    require   => [
      Exec["createdb utf8_template"],
      Postgresql::Server::Role[$ckan_test_db_user],
      Class["postgresql::server"],
    ],
  }
  exec {"paster db init":
    subscribe => [
      Exec["createdb ${ckan_db_name}"],
      File[$ckan_ini],
      Notify['virtualenv_ready'],
      Notify['ckan_fs_ready'],
    ],
    command   => "${ckan_virtualenv}/bin/paster --plugin=ckan db init --config=${ckan_ini}",
    path      => "/usr/bin:/bin:/usr/sbin",
    user      => root,
    unless    => "sudo -u postgres psql -d $ckan_db_name -c \"\\dt\" | grep package",
    logoutput => 'on_failure',
  }
  exec {"paster ga_reports init":
    subscribe => Exec["paster db init"],
    cwd       => "/vagrant/src/ckanext-ga-report",
    command   => "${ckan_virtualenv}/bin/paster initdb --config=${ckan_ini}",
    path      => "/usr/bin:/bin:/usr/sbin",
    user      => root,
    unless    => "sudo -u postgres psql -d $ckan_db_name -c \"\\dt\" | grep ga_url",
    logoutput => 'on_failure',
  }
  exec {"paster inventory init":
    subscribe => Exec["paster db init"],
    command   => "${ckan_virtualenv}/bin/paster --plugin=ckanext-dgu inventory_init --config=${ckan_ini}",
    path      => "/usr/bin:/bin:/usr/sbin",
    user      => root,
    unless    => "sudo -u postgres psql -d $ckan_db_name -c \"\\dt\" | grep inventory",
    logoutput => 'on_failure',
  }
  exec {"paster dgu_local init":
    subscribe => Exec["paster db init"],
    command   => "${ckan_virtualenv}/bin/paster --plugin=ckanext-dgu-local dgulocal init --config=${ckan_ini}",
    path      => "/usr/bin:/bin:/usr/sbin",
    user      => root,
    unless    => "sudo -u postgres psql -d $ckan_db_name -c \"\\dt\" | grep organization_extent",
    logoutput => 'on_failure',
  }
  exec {"paster archiver init":
    subscribe => Exec["paster db init"],
    command   => "${ckan_virtualenv}/bin/paster --plugin=ckanext-archiver archiver init --config=${ckan_ini}",
    path      => "/usr/bin:/bin:/usr/sbin",
    user      => root,
    unless    => "sudo -u postgres psql -d $ckan_db_name -c \"\\dt\" | grep archival",
    logoutput => 'on_failure',
  }
  exec {"paster qa init":
    subscribe => Exec["paster db init"],
    command   => "${ckan_virtualenv}/bin/paster --plugin=ckanext-qa qa init --config=${ckan_ini}",
    path      => "/usr/bin:/bin:/usr/sbin",
    user      => root,
    unless    => "sudo -u postgres psql -d $ckan_db_name -c \"\\dt\" | grep qa",
    logoutput => 'on_failure',
  }
  notify {"db_ready":
    subscribe => [
      Exec['paster inventory init'],
      Exec['paster ga_reports init'],
      Exec['paster dgu_local init'],
      Exec['paster archiver init'],
    ],
    message   => "PostgreSQL database is ready.",
  }
  # Build template databases
  file { "/tmp/create_postgis_template.sh":
    ensure => file,
    source => "puppet:///modules/dgu_ckan/create_postgis_template.sh",
    mode   => 0755,
  }
  file { "/tmp/create_utf8_template.sh":
    ensure => file,
    source => "puppet:///modules/dgu_ckan/create_utf8_template.sh",
    mode   => 0755,
  }
  exec {"createdb postgis_template":
    command => "/tmp/create_postgis_template.sh $ckan_test_db_user",
    unless  => "psql -l |grep template_postgis",
    path    => "/usr/bin:/bin",
    user    => co,
    require => [
      File["/tmp/create_postgis_template.sh"],
      Package["postgresql-${postgis_version}-postgis"],
      Postgresql::Server::Role["co"],
    ]
  }
  exec {"createdb utf8_template":
    command => "/tmp/create_utf8_template.sh",
    unless  => "psql -l |grep template_utf8",
    path    => "/usr/bin:/bin",
    user    => co,
    require => [
      File["/tmp/create_utf8_template.sh"],
      Postgresql::Server::Role["co"],
    ]
  }

  # -----------
  # Apache Solr
  # -----------

  $solr_home = "/usr/share/solr"
  $solr_logs = "/var/log/solr"
  $jetty_home = "${solr_home}/solr-4.3.1/example"
  $java_home = "/usr/lib/jvm/java-7-openjdk-${::architecture}"

  user { "solr":
    ensure => present,
  }
  file {['/etc/solr','/etc/solr/conf']:
    ensure => directory,
  }
  package {'openjdk-7-jre-headless':
    ensure => installed,
  }
  file {'/etc/init.d/jetty':
    ensure => file,
    mode   => 0755,
    source => 'puppet:///modules/dgu_ckan/jetty.sh',
  }
  file {'/etc/default/jetty':
    ensure => file,
    content => template('dgu_ckan/jetty_config.erb'),
  }
  file {$solr_logs:
    require => User['solr'],
    ensure  => directory,
    owner   => "solr",
    group   => "solr",
  }


  file {'/usr/share/solr/solr-4.3.1/example/solr/collection1/conf/solrconfig.xml':
    ensure  => file,
    path    => '/usr/share/solr/solr-4.3.1/example/solr/collection1/conf/solrconfig.xml',
    content => template('dgu_ckan/solrconfig.xml.erb'),
    require => Class['solr'],
  }

  class {'solr':
    require             => User['solr'],
    notify              => Exec['setup_solr_core'],
    install             => 'source',
    install_source      => "http://archive.apache.org/dist/lucene/solr/4.3.1/solr-4.3.1.tgz",
    #install_source     => "http://localhost/solr-4.3.1.tgz",
    install_destination => $solr_home,
  }

  exec {'setup_solr_core':
    subscribe => Class['solr'],
    command   => "chown -R solr ${jetty_home} && chgrp -R solr ${jetty_home}",
    user      => "root",
    path      => "/usr/bin:/bin:/usr/sbin",
  }
  file { "solr_schema_xml":
    require   => Class['solr'],
    ensure    => file,
    path      => "${jetty_home}/solr/collection1/conf/schema.xml",
    source    => "/vagrant/src/ckanext-dgu/config/solr/schema-2.0-dgu.xml",
    owner     => "solr",
    group     => "solr",
    mode      => 0644,
  }
  service {"jetty":
    enable    => true,
    ensure    => running,
    subscribe => [
      File["solr_schema_xml"],
      File["/etc/default/jetty"],
      File["/etc/init.d/jetty"],
      File['/etc/solr/conf'], 
      File['/usr/share/solr/solr-4.3.1/example/solr/collection1/conf/solrconfig.xml'],
    ],
  }


  # ---------
  # Webserver
  # ---------

  $ckan_apache_errorlog = "${ckan_log_root}/ckan-apache.error.log"
  $ckan_apache_customlog = "${ckan_log_root}/ckan-apache.custom.log"
  $ckan_wsgi_script = "${ckan_root}/wsgi_app.py"
  class {  'apache':
    default_vhost => false,
    mpm_module => 'prefork',
  }
  apache::mod {'wsgi':}
  apache::mod {'php5':}
  include ::apache::mod::rewrite
  include ::apache::mod::proxy
  apache::listen {'80':}
  file {[$ckan_apache_errorlog, $ckan_apache_customlog]:
    ensure => file,
    owner  => 'www-data',
    group  => 'www-data',
    mode   => 664,
  }
  file {'apache_ckan_conf':
    ensure  => file,
    path    => '/etc/apache2/sites-available/ckan.conf',
    content => template('dgu_ckan/apache-ckan.erb'),
    notify  => Exec['a2ensite ckan.conf'],
  }
  file {$ckan_wsgi_script:
    content => template('dgu_ckan/wsgi_app.py.erb'),
  }
  exec {'a2ensite ckan.conf':
    require   => [
      Class['apache'],
      Apache::Mod['wsgi'],
      Apache::Mod['php5'],
      Class['apache::mod::rewrite'],
      Class['apache::mod::proxy'],
      Apache::Listen['80'],
      File[$ckan_apache_errorlog],
      File[$ckan_apache_customlog],
      File[$ckan_wsgi_script],
      Service['jetty'],
      Notify['db_ready'],
    ],
    command   => 'a2ensite ckan.conf && service apache2 reload',
    path      => '/usr/bin:/bin:/usr/sbin',
    logoutput => 'on_failure',
  }

  # -----------
  # Redis
  # -----------
  package {'redis-server':
    ensure => installed,
  }
  dgu_ckan::pip_package { 'redis==2.9.1':
    require => Python::Virtualenv[$ckan_virtualenv],
    ensure  => present,
    owner   => 'co',
    local   => false,
  }
  service { 'redis-server':
    enable    => true,
    ensure    => running,
    require   => Package['redis-server'],
  }

  # -----------
  # Harvesting
  # -----------
  package {"rabbitmq-server":
    ensure => present,
  }

  # -----------
  # Shared assets
  # -----------
  # Setting manage_repo=true tells it to install nodejs from the chrislea PPA
  class { 'nodejs':
    manage_repo => true,
  }
  package { 'grunt-cli':
    ensure   => present,
    provider => 'npm',
    require  => Class['nodejs'],
  }
  # Why use sudo here? There is some weird permissions thing running 'npm
  # install' in puppet as the root user that causes a permissions error:
  #   2 of 3 tests failed:
  # I can replicate this on the command-line when logged in as vagrant and using sudo,
  # but it works if you do 'sudo su' or 'sudo su co' and then do 'sudo npm install'.
  exec { 'npm_deps_dgu':
    command   => 'sudo npm install',
    cwd       => '/src/ckanext-dgu',
    user      => 'co',
    require   => [
      Dgu_ckan::Pip_package[$pip_pkgs_local],
      Package['grunt-cli'],
    ],
    creates   => '/src/ckanext-dgu/node_modules',
    path      => "/usr/bin:/bin:/usr/sbin",
    logoutput => "on_failure",
  } ->
  exec {'grunt_dgu':
    require => [
      Package['grunt-cli'],
    ],
    command   => "grunt",
    cwd       => "/src/ckanext-dgu",
    user      => "co",
    path      => "/usr/bin:/bin:/usr/sbin",
  }
  exec { 'npm_deps_shared':
    command   => 'sudo npm install',
    cwd       => '/src/shared_dguk_assets',
    user      => 'co',
    require   => Package['grunt-cli'],
    creates   => '/src/shared_dguk_assets/node_modules',
    path      => "/usr/bin:/bin:/usr/sbin",
    logoutput => "on_failure",
  } ->
  exec {'grunt_shared':
    require => [
      Package['grunt-cli'],
    ],
    command   => "grunt",
    cwd       => "/src/shared_dguk_assets",
    user      => "co",
    path      => "/usr/bin:/bin:/usr/sbin",
  }

  # ---------
  # Dev tools
  # ---------
  file { "/home/co/.noserc":
    ensure => file,
    source => "puppet:///modules/dgu_ckan/noserc_template",
    mode   => 644,
  }
}

