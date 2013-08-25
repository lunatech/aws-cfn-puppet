define syslog::conf (
  $conf_file = $title,
  $conf_template,
  $tcp_port = "10514",
  $udp_port = "514",
  $loghost = "localhost") {

    include syslog

    file { $conf_file :
      content => template($conf_template),
      owner => "root",
      group => "root",
      mode => 0644,
      require => Package["rsyslog"],
      notify => Service["rsyslog"]
    }

}
