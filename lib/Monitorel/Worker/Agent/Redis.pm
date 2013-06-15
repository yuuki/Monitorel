package Monitorel::Worker::Agent::Redis;
use strict;
use warnings;

use parent qw(Monitorel::Worker);

use Carp qw(croak);
use IO::Socket::INET;

use constant {
    DEFAULT_PORT => 6379,
    STAT_NAMES => [qw(
        total_commands_processed
        connected_clients
        connected_slaves
        changes_since_last_save
        mem_fragmentation_ratio
        used_memory_rss
        expired_keys
        evicted_keys
        keyspace_hits
        keyspace_misses
        keys
    )]
};


sub proc {
    my ($class, $args) = @_;

    my $hostname = $args->{host}  or croak "host required";
    my $stats    = $args->{stats} or croak "stats required";
    my $port     = $args->{port}  || DEFAULT_PORT;

    my $sock = IO::Socket::INET->new(
        PeerAddr => "$hostname:$port",
        Proto    => 'tcp',
        Timeout  => 10,
    ) or croak "Couldn't connect to $hostname:$port";

    $sock->print("INFO\r\n");

    my $stat_to_value = {};
    $stat_to_value->{keys} = 0;
    while (my $line = $sock->getline) {
        last if $line eq "\r\n";
        $line =~ s/\n$|\r\n$//;  #chomp

        my ($stat, $value) = split ":", $line;
        next if ! defined $stat or ! defined $value;

        if ($line =~ /^db\d+:keys=(\d+),/) {
            $stat_to_value->{keys} += $1;
        } else {
            $stat_to_value->{$stat} = value_to_int($value);
        }
    }

    $sock->close;

    return +{ map { $_ => $stat_to_value->{$_} } @$stats };
}

sub value_to_int {
    my $value = shift;

    if ($value =~ /^(\d+)$/) {
        return $1;
    } elsif ($value =~ /^\d+\.\d+$/) {
        return int($value * 100);
    } else {
        return $value;
    }
}

1;
__END__
