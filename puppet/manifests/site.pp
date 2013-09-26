include datagovuk::common
#include dgu_ckan

if $::ckan=='true' {
  include datagovuk::ckan
}
if $::drupal=='true' {
  include datagovuk::drupal
}
