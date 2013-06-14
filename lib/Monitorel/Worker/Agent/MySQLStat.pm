package Monitorel::Worker::Agent::MySQLStat;
use strict;
use warnings;
use parent qw(Monitorel::Worker);

use Carp qw(croak);
use DBI;
use IO::File;

use constant MYSQL_DEFAULT_PORT => 3306;

sub proc {
    my ($class, $args) = @_;

    my $stats = $args->{stats} // croak "stats key must not be empty";
    $args->{host}   // croak "host key must not be empty";
    $args->{port}   ||= MYSQL_DEFAULT_PORT;
    $args->{dbuser} ||= 'nagios';
    $args->{dbpass} ||= 'nagios';

    my $values = _mysql_stat_to_value($args);
    my $all_stat_to_value = +{ map { $_->[0], $_->[1] } @$values };
    +{ map { $_ => $all_stat_to_value->{$_} } @$stats };
}

sub _mysql_stat_to_value {
    my ($args) = @_;

    my $dsn .= ";host=$args->{host}";
       $dsn .= ";port=$args->{port}";

    my $values;
    {
        local $SIG{ALRM} = sub { die "Timeout. 10 sec\n" };
        alarm 10;

        my $dbh = DBI->connect("dbi:mysql:$dsn",
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

    $values;
}

1;
__END__
