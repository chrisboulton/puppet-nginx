# Class to manage site resources
define nginx::site(
  Enum['absent', 'present'] $ensure     = 'present',
  Optional[Stdlib::Filesource] $source  = undef,
  String $content = '',
) {
  include nginx
  File {
    ensure  => $ensure ? {
      'absent' => 'absent',
      default  => 'present',
    },
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    notify  => Service['nginx'],
    require => File[
      '/etc/nginx/sites-available',
      '/etc/nginx/sites-enabled'
    ],
  }

  $config_file = "/etc/nginx/sites-available/${name}"

  if ($source) {
    file { $config_file:
      source => $source,
    }
  } else {
    file { $config_file:
      content => $content,
    }
  }

  if $ensure == 'present' {
    file { "/etc/nginx/sites-enabled/${name}":
      ensure => $config_file,
    }
  } else {
    file { "/etc/nginx/sites-enabled/${name}":
      ensure => 'absent',
      # This should still notify the service, as a reload will not
      # stop listening.
      notify => Service['nginx'],
    }
  }
}
