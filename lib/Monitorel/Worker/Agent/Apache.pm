package Monitorel::Worker::Agent::Apache;
use strict;
use warnings;
use utf8;
use feature qw(switch);
use parent qw(Monitorel::Worker);
use Carp qw(croak);
use LWP::UserAgent;

our $PORT  = '8081';
our $PATH  = 'server-status';
our $QUERY = 'auto';

our $STAT_NAMES = [qw(
    TotalAccesses
    TotalkBytes
    CPULoad
    Uptime
    BusyWorkers
    IdleWorkers
    TotalWorkers
)];

sub proc {
    my ($class, $args) = @_;

    my $hostname = $args->{host} // croak "host key must not be empty";
    my $stats    = $args->{stats} || $STAT_NAMES;

    my $all_stat_to_value = _apache_stat_to_value($hostname);
    +{ map { $_ => $all_stat_to_value->{$_} } @$stats };
}

sub _apache_stat_to_value {
    my $hostname = shift;

    my $response = _apache_response($hostname)
        || croak "no response";

    my $lines = [ split("\n", $response) ];
    my $kv = {};
    for (@$lines) {
        chomp;
        my ($k, $v) = _line_to_stat_to_value($_);
        $kv->{$k} = $v;
    };

    $kv;
}

sub _apache_response {
    my $hostname = shift;

    my $uri = "http://$hostname:$PORT/$PATH?$QUERY";
    my $uri_on_timeout = "http://$hostname/$PATH?$QUERY";

    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    my $response = $ua->get($uri);
    if ($response->is_error) {
        $response = $ua->get($uri_on_timeout);
    }
    $response->is_error
        and croak sprintf "Apache Error: %s: %d", $response->request->uri, $response->code;
    $response->content;
}

sub _line_to_stat_to_value {
    my $line = shift;

    my ($stat, $value) = split(/: /, $line);
    given ($stat) {
        when (/Total Accesses/) { $stat = $STAT_NAMES->[0] }
        when (/Total kBytes/  ) { $stat = $STAT_NAMES->[1] }
        when (/BusyServers/   ) { $stat = $STAT_NAMES->[4] }
        when (/IdleServers/   ) { $stat = $STAT_NAMES->[5] }
        when (/Scoreboard/    ) {
            $stat  = $STAT_NAMES->[6];
            $value = length $value
        }
    }
    ($stat, $value);
}

1;
__END__
