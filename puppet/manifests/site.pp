$python_major_version = "2"

node basenode {

  include cfn

  include ntp

  include syslog
  
  include python

  python::virtualenv { "/var/virtualenv" : }

  file { "/etc/hello.conf" :
    content => template("hello/hello.conf.erb"),
    owner => "root",
    group => "root"
    mode => 0644
  }

}

node /^cc\-.*internal$/ inherits basenode {

  syslog::conf { "/etc/rsyslog.d/99-cc.conf" :
    conf_template => "syslog/server.conf.erb"
  }

  file { [ "/var/log/hosts", "/var/log/consolidated", "/var/log/consolidated/local1", "/var/log/consolidated/local2" ] :
    ensure => directory,
    owner => "syslog",
    group => "adm",
    mode => 0755
  }

}

node /^be\-.*internal$/ inherits basenode {

  syslog::conf { "/etc/rsyslog.d/99-be.conf" :
    conf_template => "syslog/client.conf.erb",
    loghost => $cfn_cc1_address
  }

}

node /^fe\-.*internal$/ inherits basenode {

  syslog::conf { "/etc/rsyslog.d/99-fe.conf" :
    conf_template => "syslog/client.conf.erb",
    loghost => $cfn_cc1_address
  }

  class { "apache2_mod_wsgi" :
    global_wsgi_python_home => "/var/virtualenv"
  }

  file { [ "/var/www", "/var/www/html", "/var/www/wsgi" ] :
    ensure => directory,
    owner => "root",
    group => "root",
    mode =>  0755
  }

  apache2_mod_wsgi::vhost { "/etc/apache2/sites-available/default" :
    vhost_name => "*",
    port => 80,
    document_root => "/var/www/html",
    wsgi_script_aliases => {
      "/hello" => "/var/www/wsgi/hello.wsgi",
    }
  }

  file { "/var/www/wsgi/hello.wsgi" :
    source => "puppet:///modules/hello/hello.wsgi",
    owner => "root",
    group => "root",
    mode => 0644,
    require => File["/var/www/wsgi"]
  }

}
