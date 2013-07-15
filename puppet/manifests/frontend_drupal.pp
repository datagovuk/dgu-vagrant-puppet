class frontend_drupal {
  class {apache:
    default_vhost => false,
    mpm_module => 'prefork',
  }
  include apache::mod::php
}
