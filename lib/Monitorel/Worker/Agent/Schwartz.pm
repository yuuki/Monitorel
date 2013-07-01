package Monitorel::Worker::Agent::Schwartz;
use strict;
use warnings;

use Carp qw(croak);
use DBI;

use constant DEFAULT_PORT => 3306;

sub proc {
    my ($class, $args) = @_;

    my $dsn    = $args->{dsn} or croak "dsn requried";
    my $dbuser = $args->{dbuser} || 'nobody';
    my $dbpass = defined $args->{dbpass} ? $args->{dbpass} : "nobody";

    my $response = schwartz_response($dsn, $dbuser, $dbpass)
        or croak "no response";

    my $stat_to_value = {};
    for my $row (@$response) {
        my ($funcname, $count) = @$row;
        $funcname =~ s/::/-/g;
        $stat_to_value->{$funcname} = $count;
    }
    return $stat_to_value;
}

sub schwartz_response {
    my ($dsn, $dbuser, $dbpass) = @_;

    my $response = {};

    local $SIG{ALRM} = sub { croak "Schwartz timeout" };
    alarm 10;

    my $dbh = DBI->connect(
        $dsn, $dbuser, $dbpass, { RaiseError => 1 }
    ) or croak $DBI::err;
    my $sth = $dbh->prepare('
        SELECT
            funcname,
            COUNT(job.jobid) AS count
        FROM funcmap
        LEFT JOIN job
            ON funcmap.funcid = job.funcid
        GROUP BY funcmap.funcid
    ') or croak "invalid sql";
    $sth->execute;
    $response = $sth->fetchall_arrayref;
    $sth->finish;

    $dbh->disconnect;

    alarm 0;
    return $response;
}

1;
__END__
