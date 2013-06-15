package Monitorel::Worker::Agent::Plack;
use strict;
use warnings;
use parent 'Monitorel::Worker';

use Carp qw(croak);
use LWP::UserAgent;

use constant {
    PORT => '8000',
    PATH => 'server/status',
    STAT_NAMES => [qw(
        Uptime
        TotalAccesses
        BusyWorkers
        IdleWorkers
    )],
};

sub proc {
    my ($class, $args) = @_;

    my $hostname = $args->{host} or croak 'host required';
    my $stats    = $args->{stats} || STAT_NAMES;

    my $response = plack_response($hostname)
        or croak "no response";

    my $lines = [ split("\n", $response) ];
    my $stat_to_value = {};
    for my $line (@$lines) {
        chomp $line;
        my ($stat, $value) = split(/: /, $line);
        next unless $stat;

        if ($stat eq 'Uptime') {
            $stat = STAT_NAMES->[0];
            $value = [split(/ /, $value)]->[0];
        }
        elsif ($stat eq 'Total Accesses') {
            $stat = STAT_NAMES->[1];
        }
        elsif ($stat eq 'BusyWorkers') {
            $stat = STAT_NAMES->[2];
        }
        elsif ($stat eq 'IdleWorkers') {
            $stat = STAT_NAMES->[3];
        }

        $stat_to_value->{$stat} = $value;
    }

    return +{ map { $_ => $stat_to_value->{$_} } @$stats };
}

sub plack_response {
    my $hostname = shift;

    my ($port, $path) = (PORT, PATH);
    my $uri = "http://$hostname:$port/$path";

    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    my $response = $ua->get($uri);
    $response->is_error
        and croak sprintf "Plack Error: %s: %d", $response->request->uri, $response->code;
    $response->content;
}

1;
__END__
