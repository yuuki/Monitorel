package Monitorel::Worker::Agent::MySQL;
use strict;
use warnings;
use parent qw(Monitorel::Worker);

use Carp qw(croak);
use DBI;
use IO::File;

use constant DEFAULT_PORT => 3306;

sub proc {
    my ($class, $args) = @_;

    my $stats = $args->{stats} || croak "stats required";
    $args->{host}   || croak "host required";
    $args->{port}   ||= DEFAULT_PORT;
    $args->{dbuser} ||= 'nobody';
    $args->{dbpass} ||= 'nobody';

    my $dsn = "dbi:mysql:host=$args->{host};port=$args->{port}";

    my $values;
    {
        local $SIG{ALRM} = sub { die "Timeout. 10 sec\n" };
        alarm 10;

        my $dbh = DBI->connect($dsn,
                               $args->{dbuser},
                               $args->{dbpass},
                               {
                                   RaiseError => 1,
                                   PrintError => 0,
                                   AutoCommit => 1,
                               });

        my $sth = $dbh->prepare('show /*!50002 global */ status');
        $sth->execute;
        $values = $sth->fetchall_arrayref;
        $sth->finish;

        $sth = $dbh->prepare('show slave status');
        $sth->execute;
        my $slave_status = $sth->fetchrow_hashref;
        $sth->finish;
        my @kv;
        push @$values, [@kv] while @kv = each %$slave_status;

        alarm 0;
    }

    my $all_stat_to_value = +{ map { $_->[0], $_->[1] } @$values };

    return +{ map { $_ => $all_stat_to_value->{$_} } @$stats };
}

1;
__END__
