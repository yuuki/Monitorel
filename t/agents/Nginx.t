use utf8;
use strict;
use warnings;
use lib lib => 't/lib';

use Test::More;
use Test::Fatal;
use Test::Mock::LWP::Conditional;

use Monitorel::Worker::Agent::Nginx;

my $STAT_NAMES = $Monitorel::Worker::Agent::Nginx::STAT_NAMES;

subtest proc => sub {

    my $nginx_response = <<'EOS';
Active connections: 291
server accepts handled requests
 16630948 16630948 31070465
Reading: 6 Writing: 179 Waiting: 106
EOS

    my $uri = "http://localhost:8080/nginx_status";

    subtest 'normal' => sub {
        my $res = HTTP::Response->new(200);
        $res->content($nginx_response);
        Test::Mock::LWP::Conditional->stub_request($uri => $res);

        my $result = Monitorel::Worker::Agent::Nginx->proc({
            host  => 'localhost',
            stats => $STAT_NAMES,
        });

        ok $result;
        is $result->{$STAT_NAMES->[0]}, 291;
        is $result->{$STAT_NAMES->[1]}, 16630948;
        is $result->{$STAT_NAMES->[2]}, 16630948;
        is $result->{$STAT_NAMES->[3]}, 31070465;
        is $result->{$STAT_NAMES->[4]}, 6;
        is $result->{$STAT_NAMES->[5]}, 179;
        is $result->{$STAT_NAMES->[6]}, 106;

        Test::Mock::LWP::Conditional->reset_all;
    };

    subtest "invalid host" => sub {
        my $res = HTTP::Response->new(404);
        Test::Mock::LWP::Conditional->stub_request($uri => $res);

        like exception {
            Monitorel::Worker::Agent::Nginx->proc(+{
                host  => "ddd.hhh",
            });
        }, qr(Nginx Error);

        Test::Mock::LWP::Conditional->reset_all;
    };
};

done_testing;
__END__
