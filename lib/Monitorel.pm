package Monitorel;
use strict;
use warnings;
use parent qw(Amon2);
use 5.008005;
our $VERSION = "0.01";


1;
__END__

=encoding utf-8

=head1 NAME

Monitorel - A Web API providing server performance metrics graphs

=head1 SYNOPSIS

    # Enqueue Job
    use TheSchwartz;
    use Monitorel::Worker::TheSchwartz;

    my $client = TheSchwartz->new(
        databases => [{ dsn => $dsn, user => $user, pass => $passwd }],
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

    # Dequeue Job
    perl script/parallel_worker_dispatcher.pl

    # Web API for graph image (Memcached hit rate sample)
    curl http://localhost/rrdtool?s=[(def:cmd_get:::=path:localhost,memcached,cmd_get:value:AVERAGE),(def:get_hits:::=path:localhost,memcached,get_hits:value:AVERAGE),(cdef:hit_rate:::=get_hits,cmd_get,/,100,*),(line1:hit_rate:::@0000ff:hit_rate)!end=now,height=200,start=now-1d,width=400]

=head1 DESCRIPTION

Monitorel provides graph API for server metrics.
Monitorel
    - has many agent plugins such as Nginx, MySQL, SNMP, Redis, and so on.
    - stores metrics values into RRD.

=head2 SETUP SAMPLES

    # Generate rrdfiles with random metrics
    perl ./script/rrdsetup.pl

    # Access sample graph endpoint
    http://localhost:3000/samples

=head1 AUTHOR

Yuuki Tsubouchi E<lt>yuuki@cpan.orgE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
