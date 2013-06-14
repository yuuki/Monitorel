package Monitorel::Worker::Agent::Schwartz;
use strict;
use warnings;

use parent qw(Monitorel::Worker);

use DBI;
use Carp qw(croak);

use constant MYSQL_DEFAULT_PORT => 3306;

sub proc {
    my ($class, $args) = @_;

    $args->{port}     ||= MYSQL_DEFAULT_PORT;
    $args->{dbuser}   ||= 'readonly';
    $args->{dbpass}   ||= 'readonly';
    $args->{dsn}    = _search_schwartz_datasource($args);
    _schwartz_stat_to_value($args);
}

sub _schwartz_stat_to_value {
    my ($args) = @_;

    my $response = _schwartz_response($args) || croak "no response";

    my $stat_to_value = {};
    for my $row (@$response) {
        my ($funcname, $count) = @$row;
        $funcname =~ s/::/-/g;
        $stat_to_value->{$funcname} = $count;
    }
    $stat_to_value;
}

sub _search_schwartz_datasource {
    my ($args)  = @_;
    my $dsn = (grep {/theschwartz$/} DBI->data_sources('mysql', {
        host        => $args->{host},
        port        => $args->{port},
        user        => $args->{dbuser},
        password    => $args->{dbpass},
    }))[0];
    $dsn    = join(':', $dsn, $args->{host}, $args->{port});
}

sub _schwartz_response {
    my ($args)  = @_;

    my $response    = {};

    local $SIG{ALRM} = sub { croak "Schwartz timeout" };
    alarm 10;

    my $dbh = DBI->connect(
        $args->{dsn}, $args->{dbuser}, $args->{dbpass},{ RaiseError => 1 }
    ) || croak $DBI::err;
    my $sth = $dbh->prepare('
        SELECT
            funcname,
            COUNT(job.jobid) AS count
        FROM funcmap
        LEFT JOIN job
            ON funcmap.funcid = job.funcid
        GROUP BY funcmap.funcid
    ') || croak "invalid sql";
    $sth->execute;
    $response = $sth->fetchall_arrayref;
    $sth->finish;
    $dbh->disconnect;

    alarm 0;
    $response;
}

1;
__END__
