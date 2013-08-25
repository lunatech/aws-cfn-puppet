define python::script($script_file = $title, $virtualenv, $args=[]) {

  include python

  file { '/tmp/wrapper.sh' :
    ensure => 'file',
    content => template('python/wrapper.sh.erb'),
    mode => '744',
    owner => 'root',
    group => 'root'
  }

  exec { '$script_file' :
    require => [File['/tmp/wrapper.sh'], Package[$python::python_package, 'python-virtualenv']],
    command => "/tmp/wrapper.sh $virtualenv $script_file $args"
  }
      
}
