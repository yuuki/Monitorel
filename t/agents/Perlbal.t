use t::monitoreltest;

use Test::Mock::Guard qw(mock_guard);

use Monitorel::Worker::Agent::Perlbal;

subtest proc => sub {

    my $stats = [ qw(
        Requests
        Uptime
        Utime
        Stime
        CurFd
        MaxFd
    ) ];

    my $perlbal_response = [
        "max -1\n",
        "cur 0\n",
        "time: 1348718154\n",
        "pid: 3242\n",
        "utime: 0.620635 (+0.010026)\n",
        "stime: 0.20053 (+0.00323399999999999)\n",
        "reqs: 0 (+0)\n",
        "starttime 1348713284\n",
        "uptime 4870\n",
        "version 1.80\n",
    ];

    my $fd = [
        "max -1\n",
        "cur 0\n",
    ];
    my $proc = [
        "time: 1348718154\n",
        "pid: 3242\n",
        "utime: 0.620635 (+0.010026)\n",
        "stime: 0.20053 (+0.00323399999999999)\n",
        "reqs: 0 (+0)\n",
    ];
    my $uptime = [
        "starttime 1348713284\n",
        "uptime 4870\n",
        "version 1.80\n",
    ];

    my $mock = mock_guard 'Net::Telnet',
        +{
            new => sub { bless {}, shift; },
            cmd => sub {
                my ($self, %args) = @_;
                if ($args{String} eq 'fd') {
                    return @$fd;
                }
                elsif ($args{String} eq 'proc') {
                    return @$proc;
                }
                elsif ($args{String} eq 'uptime') {
                    return @$uptime;
                }
            },
            close => sub {},
        };

    my $result = Monitorel::Worker::Agent::Perlbal->proc(+{
        host  => 'localhost',
        stats => $stats,
        port  => 60000,
    });

    ok $result;
    for (@$stats) {
        ok defined $result->{$_};
    }
    is $result->{Requests}, 0;
    is $result->{Uptime}, 4870;
    is $result->{Utime}, 0.620635;
    is $result->{Stime}, 0.20053;
    is $result->{CurFd}, 0;
    is $result->{MaxFd}, -1;
};
