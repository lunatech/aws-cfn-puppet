define python::virtualenv ($virtualenv = $title) {

  include python

  exec { $virtualenv :
    command => "virtualenv --python=$python_interpreter --never-download $virtualenv",
    creates => $virtualenv,
    path => ['/bin', '/usr/bin' ],
    require => Package[$python::python_package, 'python-pip', 'python-setuptools', 'python-virtualenv']
  }

}
