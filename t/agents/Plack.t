use utf8;
use strict;
use warnings;
use lib lib => 't/lib';

use Test::More;
use Test::Mock::LWP::Conditional;

use Monitorel::Worker::Agent::Plack;


subtest proc => sub {

    my $plack_response = <<'EOS';

Uptime: 1352732489 (4 hours, 32 minutes, 40 seconds)
Total Accesses: 286129
BusyWorkers: 1
IdleWorkers: 49
--

pid status remote_addr host method uri protocol ss
21074 _ 203.104.98.218 kai3.hatenablog.com GET /feed HTTP/1.0 7
21115 _ 111.110.199.47 sirohi.hateblo.jp GET /entry/2012/08/21/image/yen.gif HTTP/1.0 0
21116 _ 59.146.210.80 lkhjkljkljdkljl.hatenablog.com GET /archive_module HTTP/1.0 1
EOS

    my $stats = [qw(
        Uptime
        TotalAccesses
        BusyWorkers
        IdleWorkers
    )];

    my $uri = "http://localhost:8000/server/status";

    subtest 'normal' => sub {
        my $res = HTTP::Response->new(200);
        $res->content($plack_response);
        Test::Mock::LWP::Conditional->stub_request($uri => $res);

        my $result = Monitorel::Worker::Agent::Plack->proc({
            host  => 'localhost',
            stats => $stats,
        });

        ok $result;
        is $result->{Uptime}, 1352732489;
        is $result->{TotalAccesses}, 286129;
        is $result->{BusyWorkers}, 1;
        is $result->{IdleWorkers}, 49;

        Test::Mock::LWP::Conditional->reset_all;
    };
};

done_testing;
