package Monitorel::Worker::Agent::Plack;
use strict;
use warnings;
use parent 'Monitorel::Worker';

use feature qw(switch);
use Carp qw(croak);
use LWP::UserAgent;

our $PORT = '8000';
our $PATH = 'server/status';

our $STAT_NAMES = [qw(
    Uptime
    TotalAccesses
    BusyWorkers
    IdleWorkers
)];

sub proc {
    my ($class, $args) = @_;

    my $hostname = $args->{host}  // croak 'host key must not be empty';
    my $stats    = $args->{stats};

    my $all_stat_to_value = _plack_stat_to_value($hostname);
    +{ map { $_ => $all_stat_to_value->{$_} } @$stats };
}

sub _plack_stat_to_value {
    my $hostname = shift;

    my $response = _plack_response($hostname) || croak "no response";

    my $lines = [ split("\n", $response) ];
    my $kv = {};
    for (@$lines) {
        chomp;
        my ($k, $v) = _line_to_stat_to_value($_);
        next unless $k;
        $kv->{$k} = $v;
    }

    $kv;
}

sub _plack_response {
    my $hostname = shift;

    my $uri = "http://$hostname:$PORT/$PATH";

    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    my $response = $ua->get($uri);
    $response->is_error
        and croak sprintf "Plack Error: %s: %d", $response->request->uri, $response->code;
    $response->content;
}

sub _line_to_stat_to_value {
    my $line = shift;

    my ($stat, $value) = split(/: /, $line);
    return () unless $stat;
    given ($stat) {
        when (/Uptime/        ) {
            $stat = $STAT_NAMES->[0];
            $value = [split(/ /, $value)]->[0];
        }
        when (/Total Accesses/) { $stat = $STAT_NAMES->[1]; }
        when (/BusyWorkers/   ) { $stat = $STAT_NAMES->[2]; }
        when (/IdleWorkers/)    { $stat = $STAT_NAMES->[3]; }
    }
    ($stat, $value);
}


1;
__END__
