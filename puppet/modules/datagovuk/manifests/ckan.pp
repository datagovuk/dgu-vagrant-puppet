class datagovuk::ckan {
  #notify {'Configuring CKAN node':}
  class { 'ckan::virtualenv': 
    virtualenv_root  => '/home/co/ckan',
    virtualenv_owner => 'co',
    virtualenv_group => 'co',
  }

  #class { 'memcached':
  #    install_dev => true
  #}
  $ckan_requirements_extra = [
    'Babel==0.9.6',
    'Beaker==1.6.3',
    'ConcurrentLogHandler==0.8.4',
    'Flask==0.8',
    'FormEncode==1.2.4',
    'GeoAlchemy==0.7.2',
    'Mako==0.8.1',
    'OWSLib==0.7.2',
    'PasteDeploy==1.5.0',
    'PasteScript==1.7.5',
    'Pygments==1.6',
    'PyMollom==0.1',
    'Shapely==1.2.17',
    'WebError==0.10.3',
    'Werkzeug==0.8.3',
    'amqplib==1.0.2',
    'anyjson==0.3.3',
    'autoneg==0.5',
    'carrot==0.10.1',
    'celery==2.4.2',
    'chardet==2.1.1',
    'ckanclient==0.10',
    'datautil==0.4',
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
    'openpyxl==1.5.7',
    'pylibmc',
    'python-gflags==2.0',
    'python-magic==0.4.3',
    'python-openid==2.2.5',
    'pytz==2012j',
    'simplejson==2.6.2',
    'vdm==0.11',
    'xlrd==0.9.2',
    'pep8==1.4.6',
  ]
}

