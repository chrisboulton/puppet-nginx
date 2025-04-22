# Class to manage NGinx configs
define nginx::config(
  Enum['absent', 'present'] $ensure     = 'present',
  Optional[Stdlib::Filesource] $source  = undef,
  String $content                       = '',
  Stdlib::Absolutepath $path            = "/etc/nginx/conf.d/${name}.conf",
) {
  if ($ensure != 'present' and $ensure != 'absent') {
    fail("Nginx::Config[${name}] ensure should be one of present/absent")
  }

  if (empty($content) and empty($source) and $ensure != 'absent') {
    fail("Nginx::Config[${name}] either source or content must be present")
  }
  elsif (!empty($content) and !empty($source)) {
    fail("Nginx::Config[${name}] cannot specify both source and content")
  }

  include nginx

  File {
    ensure  => $ensure,
    owner   => 'root',
    group   => 'root',
    require => Package['nginx'],
    notify  => Service['nginx'],
  }

  if ($content != '') {
    file { $path:
      content => $content,
    }
  }
  elsif ($ensure != 'absent') {
    file { $path:
      source => $source,
    }
  }
  else {
    file { $path : }
  }
}
