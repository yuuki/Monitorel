use utf8;
use strict;
use warnings;
use lib lib => 't/lib';

use Test::More;
use Test::Mock::Guard qw(mock_guard);

use Monitorel::Worker::Agent::Redis;

subtest proc => sub {

    my $stats = [ qw(
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

    my $redis_response = <<'EOS';
redis_version:2.4.17
redis_git_sha1:00000000
redis_git_dirty:0
arch_bits:64
multiplexing_api:kqueue
gcc_version:4.2.1
process_id:5548
run_id:bb51768da372a91b306b8f11d99dad1fcb963a12
uptime_in_seconds:4
uptime_in_days:0
lru_clock:654827
used_cpu_sys:0.01
used_cpu_user:0.00
used_cpu_sys_children:0.00
used_cpu_user_children:0.00
connected_clients:1
connected_slaves:0
client_longest_output_list:0
client_biggest_input_buf:0
blocked_clients:0
used_memory:930960
used_memory_human:909.14K
used_memory_rss:1196032
used_memory_peak:922368
used_memory_peak_human:900.75K
mem_fragmentation_ratio:1.28
mem_allocator:libc
loading:0
aof_enabled:0
changes_since_last_save:0
bgsave_in_progress:0
last_save_time:1348725548
bgrewriteaof_in_progress:0
total_connections_received:1
total_commands_processed:0
expired_keys:0
evicted_keys:0
keyspace_hits:0
keyspace_misses:0
pubsub_channels:0
pubsub_patterns:0
latest_fork_usec:0
vm_enabled:0
role:master
EOS

    my $mock = mock_guard "IO::Socket::INET",
        +{
            new => sub {
                    my $lines = [ split("\n", $redis_response), "\r\n" ];
                    bless { lines => $lines, cmd => undef }, shift;
            },
            print => sub {
                my ($self, $cmd) = @_;
                $self->{cmd} = $cmd;
            },
            getline => sub {
                my $self = shift;
                die "invalid command\n" unless $self->{cmd} =~ /^INFO/;
                my $line = shift @{ $self->{lines} };
                $line eq "\r\n" ? $line : $line . "\r\n";
            },
            close => sub {},
        };

    my $result = Monitorel::Worker::Agent::Redis->proc( +{
        host => 'localhost',
        stats => $stats,
    });

    ok $result;
    for (@$stats) {
        ok defined $result->{$_};
    }
    is $result->{total_commands_processed}, 0;
    is $result->{connected_clients},        1;
    is $result->{connected_slaves},         0;
    is $result->{changes_since_last_save},  0;
    is $result->{mem_fragmentation_ratio},  128;
    is $result->{used_memory_rss},          1196032;
    is $result->{expired_keys},             0;
    is $result->{evicted_keys},             0;
    is $result->{keyspace_hits},            0;
    is $result->{keyspace_misses},          0;
    is $result->{keys},                     0;

};

done_testing;
__END__
