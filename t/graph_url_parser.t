use utf8;
use strict;
use warnings;
use lib lib => 't/lib' => glob 'modules/*/lib';

use Test::More;
use Test::Fatal;

use Monitorel::GraphURLParser;

subtest 'simple case' => sub {
    my $body = "[(def:usage:::=path:test,mysql:value:MAX)]";
    my $parser = Monitorel::GraphURLParser->new;

    subtest parse => sub {
        my ($commands, $option) = $parser->parse($body);
        is_deeply $commands, [ 'DEF:usage=test/mysql___loadavg5.rrd:value:MAX' ];
    };

    subtest hosts => sub {
        is_deeply $parser->hosts, ['test'];
    };
};


subtest 'complex case' => sub {
    my $body = '[(def:usage:::=test.host__dskUsed.rrd:value:MAX),(def:total:::=test.host__dskTotal.rrd:value:MAX),(cdef:c_warn:::=total,0.85,*),(cdef:c_crit:::=total,0.95,*),(vdef:v_total:::=total,MINIMUM),(vrule:v_rwarn:::@FF8800::dashes=5),(hrule:v_crit:::@FF4400:"critical"),(area:usage:::@00FF00:"Disk Usage"),(line1:c_usage_predict:::@0000FF:"Predict"),(gprint:v_rwarn:::"Reach warning-85%\: %c":strftime)!s=now-1y,e=now+2y,t=Disk Usage,h=200,w=500,ll=0]';
    my $parser = Monitorel::GraphURLParser->new;

    subtest parse => sub {
        my ($commands, $option) = $parser->parse($body);

        is_deeply $commands, [
          'DEF:usage=test.host__dskUsed.rrd:value:MAX',
          'DEF:total=test.host__dskTotal.rrd:value:MAX',
          'CDEF:c_warn=total,0.85,*',
          'CDEF:c_crit=total,0.95,*',
          'VDEF:v_total=total,MINIMUM',
          'VRULE:v_rwarn#FF8800::dashes=5',
          'HRULE:v_crit#FF4400:"critical"',
          'AREA:usage#00FF00:"Disk Usage"',
          'LINE1:c_usage_predict#0000FF:"Predict"',
          'GPRINT:v_rwarn"Reach warning-85%\: %c":strftime',
        ];

        is_deeply $option, {
            '--imgformat' => 'PNG',
            '--width' => 500,
            '--height' => 200,
            '--rigid' => 1,
            '--end' => 'now+2y',
            '--start' => 'now-1y'
        };
    };

    subtest hosts => sub {
        is_deeply $parser->hosts, ['test.host'];
    };
};

subtest 'syntax error' => sub {
    my $parser = Monitorel::GraphURLParser->new;

    subtest 'tail comma' => sub {
        my $body = "[(def:usage:::=path:test,mysql:value:MAX),]";
        like exception {
            $parser->parse($body);
        }, qr(^syntax error: mismatch with <graphs>);
    };

    subtest 'tripple comma' => sub {
        my $body = "[(def:usage::=path:test,mysql:value:MAX)]";
        like exception {
            $parser->parse($body);
        }, qr(^syntax error: mismatch with <graph>);
    };
};

done_testing;
