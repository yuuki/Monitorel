use utf8;
use strict;
use warnings;
use lib lib => 't/lib';

use Test::More;
use Test::Fatal;
use Test::Mock::LWP::Conditional;

use Monitorel::Worker::Agent::Apache;


subtest proc => sub {

    my $apache_response = <<'EOS';
Total Accesses: 6407
Total kBytes: 346587
CPULoad: 12.1195
Uptime: 912
ReqPerSec: 7.02522
BytesPerSec: 389150
BytesPerReq: 55393.3
BusyWorkers: 4
IdleWorkers: 10
Scoreboard: W__..__._W_W__....._W_..................
EOS

    my $stats = [qw(
        TotalAccesses
        TotalkBytes
        Uptime
        BusyWorkers
        IdleWorkers
        TotalWorkers
    )];

    my $uri = "http://localhost:8081/server-status?auto";
    my $uri_on_timeout = "http://localhost/server-status?auto";

    subtest 'normal' => sub {
        my $res = HTTP::Response->new(200);
        $res->content($apache_response);
        Test::Mock::LWP::Conditional->stub_request($uri => $res);

        my $result = Monitorel::Worker::Agent::Apache->proc({
            host  => 'localhost',
            stats => $stats,
        });

        ok $result;
        is $result->{TotalAccesses}, 6407;
        is $result->{TotalkBytes}, 346587;
        ok !$result->{CPULoad};
        is $result->{Uptime}, 912;
        is $result->{BusyWorkers}, 4;
        is $result->{IdleWorkers}, 10;
        is $result->{TotalWorkers}, 40;

        Test::Mock::LWP::Conditional->reset_all;
    };

    subtest "invalid host" => sub {
        my $res = HTTP::Response->new(404);
        Test::Mock::LWP::Conditional->stub_request($uri => $res);

        like exception {
            Monitorel::Worker::Agent::Apache->proc({
                host  => "ddd.hhh", stats => $stats,
            });
        }, qr(Apache Error);

        Test::Mock::LWP::Conditional->reset_all;
    };

};

done_testing;
