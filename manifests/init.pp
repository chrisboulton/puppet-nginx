# - Class to install and manage nginx
class nginx(
  $config          = undef,
  $content         = undef,
  $package         = 'full',
  $version         = 'installed',
  $fastcgi_params  = '',
  $service_ensure  = 'running',
  $user            = 'www-data',
  $group           = 'www-data',
) {

  package { 'nginx':
    ensure => $version,
    name   => "nginx-${package}",
  }

  $restart_cmd = '/usr/sbin/nginx -t -c /etc/nginx/nginx.conf && (/etc/init.d/nginx status && /etc/init.d/nginx reload || /etc/init.d/nginx start)'

  service { 'nginx':
    ensure     => $service_ensure,
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    restart    => $restart_cmd,
    subscribe  => File['/etc/nginx/nginx.conf'],
  }

  if $service_ensure == 'running' {
    exec { 'reload-nginx':
      command     => $restart_cmd,
      refreshonly => true,
    }
  }
  else {
    exec { 'reload-nginx':
      command     => '/usr/bin/env true',
      refreshonly => true,
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

  if ($config and $content) {
    fail('$config and $content are both set, please choose only one to avoid unexpected behaviour')
  }

  if ($config) {
    File['/etc/nginx/nginx.conf'] {
      source => $config,
    }
  } elsif ($content) {
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
