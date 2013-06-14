use utf8;
use strict;
use warnings;
use lib lib => 't/lib';

use Test::More;
use Test::Fatal;
use Test::Mock::Guard qw(mock_guard);
use Test::Mock::LWP::Conditional;

use Monitorel::Worker::Agent::Latency;


subtest proc => sub {

    my $mock = mock_guard 'Time::HiRes',
        +{
            time => sub {
                my $begin_time = 1349418583.51932;
                my $end_time   = 1349418618.22547;
                our $time = defined $time ? $end_time : $begin_time;
            },
        };

    my $url = 'http://localhost';

    my $res = HTTP::Response->new(200);
    Test::Mock::LWP::Conditional->stub_request($url => $res);

    my $result = Monitorel::Worker::Agent::Latency->proc({
        url => $url,
    });

    ok $result->{$url};
    is $result->{$url}, 34706150;

    subtest 'invalid url' => sub {
        like exception {
            Monitorel::Worker::Agent::Latency->proc(+{
                url => 'http://ddd.hhh',
            });
        }, qr(status code);
    };

};

done_testing;
__END__
