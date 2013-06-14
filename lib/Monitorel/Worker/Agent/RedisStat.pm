package Monitorel::Worker::Agent::RedisStat;
use strict;
use warnings;

use parent qw(Monitorel::Worker);

use Carp qw(croak);
use IO::Socket::INET;

use constant REDIS_DEFAULT_PORT => 6379;

our $STAT_NAMES = [ qw(
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
) ];


sub proc {
    my ($class, $args) = @_;

    my $hostname = $args->{host}  // croak "host key must not be empty";
    my $stats    = $args->{stats} // croak "stats key must not be empty";
    my $port     = $args->{port}  || REDIS_DEFAULT_PORT;

    my $all_stat_to_value = _redis_stat_to_value($hostname, $port);
    +{ map { $_ => $all_stat_to_value->{$_} } @$stats };
}

sub _redis_stat_to_value {
    my ($hostname, $port) = @_;

    my $sock = IO::Socket::INET->new(
        PeerAddr => "$hostname:$port",
        Proto    => 'tcp',
        Timeout  => 10,
    ) or croak "Couldn't connect to $hostname:$port";

    $sock->print("INFO\r\n");

    my $item = {};
    $item->{keys} = 0;
    while (my $line = $sock->getline) {
        last if $line eq "\r\n";
        $line =~ s/\n$|\r\n$//;  #chomp

        my ($k, $v) = split ":", $line;
        next if ! defined $k or ! defined $v;

        if ($line =~ /^db\d+:keys=(\d+),/) {
            $item->{keys} += $1;
        } else {
            $item->{$k} = _value_to_int($v);
        }
    }

    $sock->close;
    $item;
}

sub _value_to_int {
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
