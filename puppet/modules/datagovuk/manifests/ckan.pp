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
}

