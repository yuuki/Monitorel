use t::monitoreltest;

use Test::Fatal;

use Monitorel::Graph::URLGenerator;

subtest graph_url_for => sub {

    subtest normal => sub {
        my ($start, $end, $width, $height, $thumbnail) = (20, 0, 120, 70, 1);

        {
            my $params = [
                def  => { vname => 'cmd_get', object => 'test.m', tag => 'memcached', label => 'cmd_get' },
                def  => { vname => 'get_hits', object => 'test.m', tag => 'memcached', label => 'get_hits' },
                cdef => { vname => 'hit_rate', value => 'cmd_get,get_hits,/' },
                line => { value => 'hit_rate', legend => 'test.m-memcached-hit_rate' },
            ];
            my $option = {
                start => $start, end => $end, width => $width, height => $height, thumbnail => $thumbnail
            };

            my $url = Monitorel::Graph::URLGenerator::graph_url_for($params, $option);
            is $url, "/rrdtool?s=[(def:cmd_get:::=path:test.m,memcached,cmd_get:value:AVERAGE),(def:get_hits:::=path:test.m,memcached,get_hits:value:AVERAGE),(cdef:hit_rate:::=cmd_get,get_hits,/),(line1:hit_rate:::\@0000ff:test.m-memcached-hit_rate)!end=$end,height=$height,start=$start,thumbnail=$thumbnail,width=$width]";
        }

        {
            my $params = [
                def  => { vname => 'cmd_get', object => 'test.m', tag => 'memcached', label => 'cmd_get' },
                def  => { vname => 'get_hits', object => 'test.m', tag => 'memcached', label => 'get_hits' },
                cdef => { vname => 'hit_rate', value => 'cmd_get,get_hits,/' },
                line => { value => 'hit_rate', legend => 'test.m-memcached-hit_rate' },
            ];

            my $url = Monitorel::Graph::URLGenerator::graph_url_for($params);
            is $url, "/rrdtool?s=[(def:cmd_get:::=path:test.m,memcached,cmd_get:value:AVERAGE),(def:get_hits:::=path:test.m,memcached,get_hits:value:AVERAGE),(cdef:hit_rate:::=cmd_get,get_hits,/),(line1:hit_rate:::\@0000ff:test.m-memcached-hit_rate)]";
        }
    };

    subtest 'arguments error' => sub {
        my $params = [
            def  => { vname => 'cmd_get', object => 'test.m', tag => 'memcached', label => 'cmd_get' },
            def  => 'hoge',
        ];

        like exception {
            Monitorel::Graph::URLGenerator::graph_url_for($params);
        }, qr(^param must be Hashref: def);

        like exception {
            Monitorel::Graph::URLGenerator::graph_url_for( $params, 'hoge');
        }, qr(^global option must be Hashref);
    };

};
