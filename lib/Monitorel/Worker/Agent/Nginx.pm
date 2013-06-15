package Monitorel::Worker::Agent::Nginx;
use strict;
use warnings;
use parent 'Monitorel::Worker';

use Carp qw(croak);
use LWP::UserAgent;

use constant {
    PORT       => '8080',
    PATH       => 'nginx_status',
    STAT_NAMES => [qw(
        ActiveConnections
        AcceptedConnections
        HandledConnections
        Requests
        Reading
        Writing
        Waiting
    )],
};

sub proc {
    my ($class, $args) = @_;

    my $hostname = $args->{host} or croak 'host required';
    my $stats    = $args->{stats} || STAT_NAMES;
    my $port     = $args->{port}  || PORT;
    my $path     = $args->{path}  || PATH;

    my $response = nginx_response($hostname, $port, $path)
        or croak "no response";
    my $lines = [ split("\n", $response) ];

    my $stat_to_value = {};

    # line 1
    $lines->[0] =~ /^Active connections: (\d+)/;
    $stat_to_value->{STAT_NAMES->[0]} = $1;

    # line 2, 3
    my $keys   = [ split(" ", $lines->[1]) ];
    my $values = [ split(/ /, $lines->[2]) ];
    shift $values; # discard head's ''
    if ($keys->[1] eq "accepts") {
        $stat_to_value->{STAT_NAMES->[1]} = $values->[0];
    }
    if ($keys->[2] eq "handled") {
        $stat_to_value->{STAT_NAMES->[2]} = $values->[1];
    }
    if ($keys->[3] eq "requests") {
        $stat_to_value->{STAT_NAMES->[3]} = $values->[2];
    }

    # line 4
    $lines->[3] =~ /Reading: (\d+) Writing: (\d+) Waiting: (\d+)/;
    $stat_to_value->{STAT_NAMES->[4]} = $1;
    $stat_to_value->{STAT_NAMES->[5]} = $2;
    $stat_to_value->{STAT_NAMES->[6]} = $3;

    return +{ map { $_ => $stat_to_value->{$_} } @$stats };
}

sub nginx_response {
    my ($hostname, $port, $path) = @_;

    my $uri = "http://$hostname:$port/$path";

    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    my $response = $ua->get($uri);
    $response->is_error
        and croak sprintf "Nginx Error: %s: %d", $response->request->uri, $response->code;
    return $response->content;
}

1;
__END__
