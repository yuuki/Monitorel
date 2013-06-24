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

Monitorel - Provide graph API for server metrics

=head1 SYNOPSIS

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


=head1 DESCRIPTION

Monitorel provides graph API for server metrics.
Monitorel
    - has many agent plugins such as Nginx, MySQL, SNMP, Redis, and so on.
    - stores metrics values into RRD.

=head1 AUTHOR

Yuuki Tsubouchi E<lt>yuuki@cpan.orgE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
