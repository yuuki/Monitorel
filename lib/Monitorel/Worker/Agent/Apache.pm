package Monitorel::Worker::Agent::Apache;
use strict;
use warnings;
use utf8;
use parent qw(Monitorel::Worker);

use Carp qw(croak);
use LWP::UserAgent;

use constant {
    PORT  => '8081',
    PATH  => 'server-status',
    QUERY => 'auto',
    STAT_NAMES => [qw(
        TotalAccesses
        TotalkBytes
        CPULoad
        Uptime
        BusyWorkers
        IdleWorkers
        TotalWorkers
    )],
};


sub proc {
    my ($class, $args) = @_;

    my $hostname = $args->{host}
        || croak "host required";
    my $stats = $args->{stats} || STAT_NAMES;

    my $response = apache_response($hostname)
        || croak "no response";

    my $lines = [ split("\n", $response) ];
    my $all_stat_to_value = {};
    for my $line (@$lines) {
        chomp $line;

        my ($stat, $value) = split(/: /, $line);
        if ($stat eq 'Total Accesses') {
            $stat = STAT_NAMES->[0];
        }
        elsif ($stat eq 'Total kBytes') {
            $stat = STAT_NAMES->[1];
        }
        elsif ($stat eq 'BusyServers') {
            $stat = STAT_NAMES->[4];
        }
        elsif ($stat eq 'IdleServers') {
            $stat = STAT_NAMES->[5];
        }
        elsif ($stat eq 'Scoreboard') {
            $stat  = STAT_NAMES->[6];
            $value = length $value;
        }
        $all_stat_to_value->{$stat} = $value;
    };

    return +{ map { $_ => $all_stat_to_value->{$_} } @$stats };
}

sub apache_response {
    my $hostname = shift;

    my ($port, $path, $query) = (PORT, PATH, QUERY);
    my $uri = "http://$hostname:$port/$path?$query";
    my $uri_on_timeout = "http://$hostname/$path?$query";

    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    my $response = $ua->get($uri);
    if ($response->is_error) {
        $response = $ua->get($uri_on_timeout);
    }
    $response->is_error
        and croak sprintf "Apache Error: %s: %d", $response->request->uri, $response->code;
    return $response->content;
}

1;
__END__
