# == Class: monit
#
# This module controls Monit
#
# === Parameters
#
# [*ensure*]     - If you want the service running or not
# [*admin*]      - Admin email address
# [*interval*]   - How frequently the check runs
# [*delay*]      - How long to wait before actually performing any action
# [*logfile*]    - What file for monit use for logging
# [*mailserver*] - Which mailserver to use
# [*httpd*]         - Enable web server or not
# [*httpd_address*] - Restrict interface
# [*httpd_allow*]   - Array of allow statements (users, groups, hosts)
# [*httpd_port*]    - Port to use (default: 2812)
# [*httpd_ssl*]     - Enable SSL (default: false)
# [*httpd_ssl_pem*] - Path to SSL pem file
#
# === Examples
#
#  class { 'monit':
#    admin    => 'me@mydomain.local',
#    interval => 30,
#  }
#
# === Authors
#
# Eivind Uggedal <eivind@uggedal.com>
# Jonathan Thurman <jthurman@newrelic.com>
#
# === Copyright
#
# Copyright 2011 Eivind Uggedal <eivind@uggedal.com>
#
class monit (
  $ensure        = present,
  $admin         = undef,
  $interval      = 60,
  $delay         = $interval * 2,
  $logfile       = $monit::params::logfile,
  $mailserver    = 'localhost',
  $httpd         = true,
  $httpd_address = 'localhost',
  $httpd_allow   = ['localhost'],
  $httpd_port    = 2812,
#  $httpd_ssl     = false,
#  $httpd_ssl_pem = '',
) inherits monit::params {

  $conf_include = "${monit::params::conf_dir}/*"

  if ($ensure == 'present') {
    $run_service = true
    $service_state = 'running'
  } else {
    $run_service = false
    $service_state = 'stopped'
  }

  package { $monit::params::monit_package:
    ensure => $ensure,
  }

  # Template uses: $admin, $conf_include, $interval, $logfile
  file { $monit::params::conf_file:
    ensure  => $ensure,
    content => template('monit/monitrc.erb'),
    mode    => '0600',
    require => Package[$monit::params::monit_package],
    notify  => Service[$monit::params::monit_service],
  }

  file { $monit::params::conf_dir:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  # Not all platforms need this
  if ($monit::params::default_conf) {
    if ($monit::params::default_conf_tpl) {
      file { $monit::params::default_conf:
        ensure  => $ensure,
        content => template("monit/$monit::params::default_conf_tpl"),
        require => Package[$monit::params::monit_package],
      }

    }
    else { fail("You need to provide config template")}
  }

  # Template uses: $logfile
  file { $monit::params::logrotate_script:
    ensure  => $ensure,
    content => template("monit/${monit::params::logrotate_source}"),
    require => Package[$monit::params::monit_package],
  }

  service { $monit::params::monit_service:
    ensure     => $service_state,
    enable     => $run_service,
    hasrestart => true,
    hasstatus  => true,
    subscribe  => File[$monit::params::conf_file],
    require    => [
      File[$monit::params::conf_file],
      File[$monit::params::logrotate_script]
    ],
  }
}
