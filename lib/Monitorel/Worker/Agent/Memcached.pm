package Monitorel::Worker::Agent::Memcached;
use strict;
use warnings;
use parent qw(Monitorel::Worker);

use Carp qw(croak);
use IO::Socket::INET;


use constant {
    DEFAULT_PORT => 11211,
    STAT_NAMES   => [qw(
        accepting_conns
        auth_cmds
        auth_errors
        bytes
        bytes_read
        bytes_written
        cas_badval
        cas_hits
        cas_misses
        cmd_flush
        cmd_get
        cmd_set
        cmd_touch
        conn_yields
        connection_structures
        curr_connections
        curr_items
        decr_hits
        decr_misses
        delete_hits
        delete_misses
        evicted_unfetched
        evictions
        expired_unfetched
        get_hits
        get_misses
        hash_bytes
        hash_is_expanding
        hash_power_level
        incr_hits
        incr_misses
        libevent
        limit_maxbytes
        listen_disabled_num
        pid
        pointer_size
        reclaimed
        reserved_fds
        rusage_system
        rusage_user
        threads
        time
        total_connections
        total_items
        touch_hits
        touch_misses
        uptime
        version
    )]
};

sub proc {
    my ($class, $args) = @_;

    my $hostname = $args->{host}  or croak "host required";
    my $stats    = $args->{stats} || STAT_NAMES;
    my $port     = $args->{port}  || DEFAULT_PORT;

    my $sock = IO::Socket::INET->new(
        PeerAddr => "$hostname:$port",
        Proto    => 'tcp',
        Timeout  => 10,
    ) or croak "Couldn't connect to $hostname:$port";

    $sock->print("stats\r\n");

    my $all_stat_to_value = {};
    while (my $line = $sock->getline) {
        last if $line =~ /^END/;
        $line =~ s/\n$|\r\n$//;  #chomp
        if ($line =~ /^STAT\s+(\S*)\s+(.*)/) {
            $all_stat_to_value->{$1} = $2;
        }
    }

    $sock->close;

    return +{ map { $_ => $all_stat_to_value->{$_} } @$stats };
}

1;
__END__
