class nginx($package = 'full', $version = 'installed', $config = '', $fastcgi_params = '') {
    package { 'nginx':
        name => "nginx-${package}",
        ensure => $version,
    }

    service { 'nginx':
        ensure => running,
        enable => true,
        hasrestart => true,
        hasstatus => true,
        subscribe => File['/etc/nginx/nginx.conf'],
    }

    exec { 'reload-nginx':
        command => '/etc/init.d/nginx reload',
        refreshonly => true,
    }

    file { [
        '/etc/nginx/logs.d/',
        '/etc/nginx/conf.d/',
        '/etc/nginx/upstreams.d/',
        '/etc/nginx/sites-enabled',
        '/etc/nginx/sites-available'
    ]:
		ensure  => 'directory',
		owner   => 'root',
		group   => 'root',
		mode    => '0755',
		require => Package['nginx'],
	}

	$use_config = $config ? {
	    ''      => 'puppet:///modules/nginx/nginx.conf',
	    default => $config,
	}

    file { '/etc/nginx/nginx.conf':
        ensure  => 'present',
        source  => $use_config,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['nginx'],
        notify  => Exec['reload-nginx'],
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
        notify  => Exec['reload-nginx'],
	}

	file { '/var/cache/nginx/':
		ensure => directory,
		owner => 'www-data',
		group => 'www-data',
		mode => 0750,
	}

	# remove the default site
	nginx::site { 'default':
		ensure => absent,
	}
}
