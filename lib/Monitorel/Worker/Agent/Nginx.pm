package Monitorel::Worker::Agent::Nginx;
use strict;
use warnings;
use parent 'Monitorel::Worker';

use feature qw(switch);
use Carp qw(croak);
use LWP::UserAgent;

our $PORT = '8080';
our $PATH = 'nginx_status';

our $STAT_NAMES = [qw(
    ActiveConnections
    AcceptedConnections
    HandledConnections
    Requests
    Reading
    Writing
    Waiting
)];

sub proc {
    my ($class, $args) = @_;

    my $hostname = $args->{host}  // croak 'host key must not be empty';
    my $stats    = $args->{stats} || $STAT_NAMES;
    my $port     = $args->{port}  || $PORT;
    my $path     = $args->{path}  || $PATH;

    my $all_stat_to_value = _nginx_stat_to_value($hostname, $port, $path);
    +{ map { $_ => $all_stat_to_value->{$_} } @$stats };
}

sub _nginx_stat_to_value {
    my ($hostname, $port, $path) = @_;

    my $response = _nginx_response($hostname, $port, $path) || croak "no response";
    my $lines = [ split("\n", $response) ];

    my $stat_to_value = {};

    # line 1
    $lines->[0] =~ /^Active connections: (\d+)/;
    $stat_to_value->{$STAT_NAMES->[0]} = $1;

    # line 2, 3
    my $keys   = [ split(" ", $lines->[1]) ];
    my $values = [ split(/ /, $lines->[2]) ];
    shift $values; # discard head's ''
    if ($keys->[1] eq "accepts") {
        $stat_to_value->{$STAT_NAMES->[1]} = $values->[0];
    }
    if ($keys->[2] eq "handled") {
        $stat_to_value->{$STAT_NAMES->[2]} = $values->[1];
    }
    if ($keys->[3] eq "requests") {
        $stat_to_value->{$STAT_NAMES->[3]} = $values->[2];
    }

    # line 4
    $lines->[3] =~ /Reading: (\d+) Writing: (\d+) Waiting: (\d+)/;
    $stat_to_value->{$STAT_NAMES->[4]} = $1;
    $stat_to_value->{$STAT_NAMES->[5]} = $2;
    $stat_to_value->{$STAT_NAMES->[6]} = $3;

    $stat_to_value;
}

sub _nginx_response {
    my ($hostname, $port, $path) = @_;

    my $uri = "http://$hostname:$port/$path";

    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    my $response = $ua->get($uri);
    $response->is_error
        and croak sprintf "Nginx Error: %s: %d", $response->request->uri, $response->code;
    $response->content;
}

1;
__END__
