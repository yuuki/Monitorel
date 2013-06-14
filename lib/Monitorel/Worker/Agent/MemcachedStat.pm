package Monitorel::Worker::Agent::MemcachedStat;
use strict;
use warnings;
use parent qw(Monitorel::Worker);

use Carp qw(croak);
use IO::Socket::INET;

our $MEMCACHED_DEFAULT_PORT = 11211;

our $STAT_NAMES = [ qw(
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
) ];

sub proc {
    my ($class, $args) = @_;

    my $hostname = $args->{host}  // croak "host key must not be empty";
    my $stats    = $args->{stats} // croak "stats key must not be empty";
    my $port     = $args->{port}  || $MEMCACHED_DEFAULT_PORT;

    my $all_stat_to_value = _memcached_stat_to_value($hostname, $port)
        || croak "No memcached response";
    +{ map { $_ => $all_stat_to_value->{$_} } @$stats };
}

sub _memcached_stat_to_value {
    my ($hostname, $port) = @_;

    my $sock = IO::Socket::INET->new(
        PeerAddr => "$hostname:$port",
        Proto    => 'tcp',
        Timeout  => 10,
    ) or croak "Couldn't connect to $hostname:$port";

    $sock->print("stats\r\n");

    my $items = {};
    while (my $line = $sock->getline) {
        last if $line =~ /^END/;
        $line =~ s/\n$|\r\n$//;  #chomp
        if ($line =~ /^STAT\s+(\S*)\s+(.*)/) {
            $items->{$1} = $2;
        }
    }

    $sock->close;
    $items;
}

1;
__END__
