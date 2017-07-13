node 'sensu-server' {
  class { '::sensu':
    install_repo      => true,
    server            => true,
    manage_services   => true,
    manage_user       => true,
    rabbitmq_password => 'correct-horse-battery-staple',
    rabbitmq_vhost    => '/sensu',
    api               => true,
    api_user          => 'admin',
    api_password      => 'secret',
    client_address    => $::ipaddress_eth1,
    subscriptions     => ['all', 'roundrobin:poller'],
  }

  sensu::handler { 'default':
    command => 'mail -s \'sensu alert\' ops@example.com',
  }

  sensu::check { 'check_ntp':
    command     => 'PATH=$PATH:/usr/lib64/nagios/plugins check_ntp_time -H pool.ntp.org -w 30 -c 60',
    handlers    => 'default',
    subscribers => 'sensu-test',
  }

  $proxy_requests = {
    'client_attributes' => {
      'subscriptions' => 'eval: value.include?("ntp")',
    },
  }

  # Example check using the cron schedule.
  sensu::check { 'remote_check_ntp':
    command        => 'PATH=$PATH:/usr/lib64/nagios/plugins check_ntp_time -H :::address::: -w 30 -c 60',
    standalone     => false,
    handlers       => 'default',
    subscribers    => 'roundrobin:poller',
    cron           => '*/5 * * * *',
    proxy_requests => $proxy_requests,
  }
}
