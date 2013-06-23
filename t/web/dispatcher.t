use t::monitoreltest;

use Test::Fatal;
use Test::Mock::Guard qw(mock_guard);
use Plack::Test;
use Plack::Util;

use Monitorel::Web;

my $app = Plack::Util::load_psgi 'script/app.psgi';

subtest 'rrdtool' => sub {
    test_psgi
        app => $app,
        client => sub {
            my $cb = shift;

            my $mock = mock_guard 'RRDTool::Rawish' => {
                graph => sub { 'dummy' },
            };

            my $req = HTTP::Request->new(GET => 'http://localhost/rrdtool?s=[(def:cmd_get:::=path:localhost,memcached,cmd_get:value:AVERAGE),(def:get_hits:::=path:localhost,memcached,get_hits:value:AVERAGE),(cdef:hit_rate:::=get_hits,cmd_get,/,100,*),(line1:hit_rate:::@0000ff:hit_rate)!end=now,height=200,start=now-1d,width=400]');
            my $res = $cb->($req);
            is $res->code, 200;
            diag $res->content if $res->code != 200;
        };
};
