class python {

  case $python_major_version {
    "2" : {
      $python_package = "python-minimal"
      $mod_wsgi_package = "libapache2-mod-wsgi"
      $python_interpreter = "python"
    }
    "3" : {
      $python_package = "python3-minimal"
      $mod_wsgi_package = "libapache2-mod-wsgi-py3"
      $python_interpreter = "python3"
    }
    default : {
      fail("Unrecognized or missing value for 'python_major_version'")
    }
  }

  # base python 2 package
  package { $python_package :
    ensure => installed
  }

  # pip
  package { 'python-pip' :
    ensure => installed
  }

  # setuptools/distribute
  package { 'python-setuptools' :
    ensure => installed
  }

  # virtualenv
  package { 'python-virtualenv' :
    ensure => installed
  }

}
