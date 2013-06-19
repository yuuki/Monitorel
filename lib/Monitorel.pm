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

Monitorel - Generate graph for server statistics

=head1 SYNOPSIS

    use TheSchwartz;
    use Monitorel::Worker::Agent::Nginx;

    my $rrd_dir = 'path/to/rrdfile_dir';
    Monitorel::Worker::Store::RRD::Path->set_rrddir($rrd_dir);

    my $client = TheSchwartz->new(
        databases => [{ dsn => $dsn, user => $user, passwd => $passwd }],
        verbose   => 1,
    );

    my $job_id = $client->insert('Monitorel::Worker::Agent::Nginx', {
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

Monitorel::Worker is TheSchwartz worker for retriving several server statistics.
Monitorel::Worker
    - has many plugins such as Nginx, MySQL, SNMP, Redis, and so on.
    - stores statistics values into RRD.

=head1 AUTHOR

Yuuki Tsubouchi E<lt>yuuki@cpan.orgE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
__END__


=head1 NAME

Monitorel - It's new $module

=head1 SYNOPSIS

    use Monitorel;

=head1 DESCRIPTION

Monitorel is ...

=head1 LICENSE

Copyright (C) y_uuki

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

y_uuki E<lt>yuki.tsubo@gmail.comE<gt>

