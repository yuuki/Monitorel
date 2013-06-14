use utf8;
use strict;
use warnings;
use lib lib => 't/lib';

use Test::More;
use Test::Mock::Guard qw(mock_guard);

use Monitorel::Worker::Agent::MemcachedStat;

subtest proc => sub {

    my $stats = [ qw(
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
        ) ];

    my $memcached_response = <<'EOS';
STAT        accepting_conns     1
STAT        auth_cmds           0
STAT        auth_errors         0
STAT        bytes               0
STAT        bytes_read          7
STAT        bytes_written       0
STAT        cas_badval          0
STAT        cas_hits            0
STAT        cas_misses          0
STAT        cmd_flush           0
STAT        cmd_get             0
STAT        cmd_set             0
STAT        cmd_touch           0
STAT        conn_yields         0
STAT        connection_structures 11
STAT        curr_connections    10
STAT        curr_items          0
STAT        decr_hits           0
STAT        decr_misses         0
STAT        delete_hits         0
STAT        delete_misses       0
STAT        evicted_unfetched   0
STAT        evictions           0
STAT        expired_unfetched   0
STAT        get_hits            0
STAT        get_misses          0
STAT        hash_bytes          524288
STAT        hash_is_expanding   0
STAT        hash_power_level    16
STAT        incr_hits           0
STAT        incr_misses         0
STAT        libevent            2.0.20-stable
STAT        limit_maxbytes      67108864
STAT        listen_disabled_num 0
STAT        pid                 3892
STAT        pointer_size        64
STAT        reclaimed           0
STAT        reserved_fds        20
STAT        rusage_system       0.001846
STAT        rusage_user         0.000711
STAT        threads             4
STAT        time                1348217604
STAT        total_connections   11
STAT        total_items         0
STAT        touch_hits          0
STAT        touch_misses        0
STAT        uptime              7
STAT        version             1.4.14
END
EOS

    my $mock = mock_guard "IO::Socket::INET",
        +{
            new => sub {
                my $lines = [ split '\n', $memcached_response ];
                bless {lines => $lines, cmd => undef}, shift;
            },
            print => sub {
                my ($self, $cmd) = @_;
                $self->{cmd} = $cmd;
            },
            getline => sub {
                my $self = shift;
                die "invalid command\n" unless $self->{cmd} =~ /^stats/;
                (shift @{ $self->{lines} }) . "\r\n";
            },
            close => sub {},
        };

    my $result = Monitorel::Worker::Agent::MemcachedStat->proc(+{
        host  => 'localhost',
        stats => $stats,
    });

    ok $result;
    for (@$stats) {
        ok defined $result->{$_};
    }
    is $result->{bytes},            0;
    is $result->{limit_maxbytes},   67108864;
    is $result->{bytes_read},       7;
    is $result->{bytes_written},    0;
    is $result->{cmd_get},          0;
    is $result->{cmd_set},          0;
    is $result->{get_hits},         0;
    is $result->{get_misses},       0;
    is $result->{curr_connections}, 10;
    is $result->{evictions},        0;

};

done_testing;
__END__
