# NAME

Monitorel - Generate graph for server metrics

# SYNOPSIS

```perl
    use TheSchwartz;
    use Monitorel::Worker::TheSchwartz;

    my $client = TheSchwartz->new(
        databases => [{ dsn => $dsn, user => $user, passwd => $passwd }],
    );

    my $job_id = $client->insert('Monitorel::Worker::TheSchwartz', {
        agent => 'Nginx',
        fqdn  => 'localhost',
        stats => [qw(ActiveConnections AcceptedConnections Requests)],
        tag   => 'nginx',   # Option
        type  => {          # Option
            ActiveConnections   => 'gauge',
            AcceptedConnections => 'derive',
            Requests            => 'derive',
        },
        label => {          # Option
            ActiveConnections   => 'active',
            AcceptedConnections => 'accepted',
            Requests            => 'requests',
        },
    });
```

# DESCRIPTION

Monitorel provides graph API for server metrics.
Monitorel
    - has many agent plugins such as Nginx, MySQL, SNMP, Redis, and so on.
    - stores metrics values into RRD.

# LICENSE

Copyright (C) y\_uuki

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

y\_uuki <yuki.tsubo@gmail.com>
