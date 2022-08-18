# @summery small class to manage puppet using puppet apply
# @param packages list of packages to install
# @param users list of user to create
class puppet_apply (
    Array[String]      $packages,
    Hash[String, Hash] $users,
) {
    ensure_packages($packages)
    file { '/etc/hostname':
        ensure  => file,
        content => "${facts['networking']['fqdn']}\n",
    }
    file { '/etc/puppet/hiera.yaml':
        ensure  => file,
        content => file('puppet_apply/hiera.yaml'),
    }
    file { '/usr/local/bin/puppet-apply':
        ensure  => file,
        content => file('puppet_apply/puppet-apply'),
        mode    => '0550',
    }
    cron { 'puppet-apply':
        ensure  => present,
        minute  => 5,
        command => '/usr/local/bin/puppet-apply',
        require => File['/usr/local/bin/puppet-apply'],
    }
    $users.each |String $user, Hash $config| {
        user { $user:
            * => $config['user'],
        }
        ssh_authorized_key { "${user} ssh key":
            user => $user,
            *    => $config['ssh_authorized_key'],
        }
        file { "/home/${user}":
            ensure  => directory,
            mode    => '0600',
            owner   => $user,
            group   => $user,
            recurse => 'remote',
            source  => "puppet:///modules/puppet_apply/users/${user}",
        }
    }
}
