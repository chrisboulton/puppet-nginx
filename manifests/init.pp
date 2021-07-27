# - Class to install and manage nginx
class nginx(
  String $config                              = '',
  String $content                             = '',
  String $package                             = 'full',
  String $version                             = 'installed',
  String $fastcgi_params                      = '',
  Enum['stopped', 'running'] $service_ensure  = 'running',
  String $user                                = 'www-data',
  String $group                               = 'www-data',
  Integer $worker_connections                 = 1024,
  Integer $worker_processes                   = 2,
) {

  package { 'nginx':
    ensure => $version,
    name   => "nginx-${package}",
  }

  service { 'nginx':
    ensure     => $service_ensure,
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    restart    => '/usr/sbin/nginx -t -c /etc/nginx/nginx.conf && /etc/init.d/nginx reload',
    subscribe  => File['/etc/nginx/nginx.conf'],
  }

  # DEPRECATED: use `notify => Service['nginx']` instead.
  # This remains for backwards compatiblity with other modules.
  # Previously, this would execute the same command as the custom restart above. Both the service and the exec
  # doing the reload simultaneously would cause a race condition resulting in nginx to fail to reload correctly.
  exec { 'reload-nginx':
    command     => '/usr/bin/env true',
    refreshonly => true,
  }

  if $service_ensure == 'running' {
    Exec['reload-nginx'] {
      notify => Service['nginx'],
    }
  }

  file { ['/etc/nginx/conf.d/',
    '/etc/nginx/upstreams.d/',
    '/etc/nginx/sites-enabled',
    '/etc/nginx/sites-available']:
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => Package['nginx'],
  }

  file { '/etc/nginx/nginx.conf':
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Package['nginx'],
    notify  => Service['nginx'],
  }

  if ($config != '' and $content != '') {
    fail('$config and $content are both set, please choose only one to avoid unexpected behaviour')
  }

  if ($config != '') {
    File['/etc/nginx/nginx.conf'] {
      source => $config,
    }
  } elsif ($content != '') {
    File['/etc/nginx/nginx.conf'] {
      content => $content,
    }
  } else {
    File['/etc/nginx/nginx.conf'] {
      content => template('nginx/nginx.conf.erb'),
    }
  }

  $use_fastcgi_params = $fastcgi_params ? {
    ''      => 'puppet:///modules/nginx/fastcgi_params',
    default => $fastcgi_params,
  }

  file { '/etc/nginx/fastcgi_params':
    ensure  => 'present',
    source  => $use_fastcgi_params,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Package['nginx'],
    notify  => Service['nginx'],
  }

  file { '/var/cache/nginx/':
    ensure => 'directory',
    owner  => $user,
    group  => $group,
    mode   => '0750',
  }

  # remove the default site
  nginx::site { 'default':
    ensure => 'absent',
  }
}
