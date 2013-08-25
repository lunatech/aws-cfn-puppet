define apache2_mod_wsgi::vhost (
  $document_root,
  $vhost_name,
  $port,
  $wsgi_script_root = undef,
  $wsgi_script_aliases = undef,
  $vhost_conf_template = 'apache2_mod_wsgi/vhost.conf.erb',
  $vhost_conf_file = $title) {

    include apache2_mod_wsgi
    
    file { $vhost_conf_file :
      content => template($vhost_conf_template),
      owner => 'root',
      group => 'root',
      mode => 0644,
      require => Package['apache2'],
      notify => Service['apache2']
    }
    
  }
