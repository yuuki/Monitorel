#!/usr/bin/env perl
use utf8;
use strict;
use warnings;
use lib 'lib';

use RRDTool::Rawish;

use Monitorel::Worker::Store::RRD;

# for development
$ENV{PLACK_ENV} = 'development';

my $HOST = 'localhost';
my $TAGS = {
    _default => [qw(
        netin
        netout
        cpuuser
        cpunice
        cpukernel
        cpuwait
        cpuidle
        cpuinterrupt
        cpusoftirq
        ioread
        iowrite
        loadavg5
        loadavg15
        memAvailReal
        memTotalReal
        memAvailSwap
        memTotalSwap
        memShared
        memCached
        memBuffer
        dskAvail
        dskTotal
        dskUsed
        uptime
    )],
    apache => [qw(
        TotalAccesses
        TotalkBytes
        CPULoad
        Uptime
        BusyWorkers
        IdleWorkers
        TotalWorkers
    )],
    nginx => [qw(
        ActiveConnections
        AcceptedConnections
        HandledConnections
        Requests
        Reading
        Writing
        Waiting
    )],
    mysql => [qw(
        Bytes_received
        Bytes_sent
        Com_insert
        Com_select
        Com_update
        Com_update_multi
        Com_delete
        Com_delete_multi
        Com_replace
        Com_set_option
        Connections
        Threads_cached
        Threads_connected
        Threads_created
        Threads_running
    )],
    memcached => [qw(
        bytes
        limit_maxbytes
        bytes_read
        bytes_written
        cmd_get
        cmd_set
        get_hits
        get_misses
        curr_connections
        evictions
    )],
    plack => [qw(
        TotalAccesses
        TotalkBytes
        CPULoad
        Uptime
        BusyWorkers
        IdleWorkers
        TotalWorkers
    )],
    redis => [qw(
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
    )],
};
my $DT = 600;

for my $tag (keys %$TAGS) {
    my $args = {
        fqdn  => $HOST,
        tag   => $tag,
    };
    for my $stat (@{$TAGS->{$tag}}) {
        my $rrd = Monitorel::Worker::Store::RRD->new($args, $stat);
        $rrd->create;
        for my $i (99..0) {
            $rrd->update(time - $DT*$i, rand(100));
        }
    }
}
