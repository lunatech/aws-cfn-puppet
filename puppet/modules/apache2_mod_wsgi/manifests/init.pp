class apache2_mod_wsgi (
  $wsgi_conf_file = '/etc/apache2/mods-available/wsgi.conf',
  $global_wsgi_python_home = undef) {

  # base apache2 package
  package { 'apache2' :
    ensure => installed,
  }

  # mod_wsgi compiled with appropriate python and apache2
  package { $python::mod_wsgi_package :
    ensure => installed,
    require => Package['apache2', $python::python_package]
  }

  # server-wide config file for mod_wsgi
  file { 'wsgi.conf' :
    ensure => file,
    mode   => 0644,
    content => template('apache2_mod_wsgi/wsgi.conf.erb'),
    path   => "$wsgi_conf_file",
    require => Package['apache2', $python::mod_wsgi_package ]
  }

  service { 'apache2' :
    ensure    => running,
    enable    => true,
    subscribe => File['wsgi.conf']
  }
  
}
