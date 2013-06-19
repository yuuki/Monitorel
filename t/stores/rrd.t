use t::monitoreltest;

use Cwd qw(getcwd);

use Monitorel::Worker::Store::RRD;
use Monitorel::Worker::Store::RRD::Path;

my $rrd_dir = getcwd . '/tmp';
Monitorel::Worker::Store::RRD::Path->set_rrddir($rrd_dir);

my $rrd = Monitorel::Worker::Store::RRD->new({
    fqdn  => 'localhost',
    tag   => 'test',
    label => { response_num => 'y_uuki' },
    type  => { response_num => 'derive' },
}, 'response_num');

subtest constructer => sub {
    if (ok $rrd) {
        isa_ok $rrd, 'Monitorel::Worker::Store::RRD';
        is $rrd->{stat}, 'response_num';
        is $rrd->{type}, 'DERIVE';
        isa_ok $rrd->{rrd}, 'RRDTool::Rawish';
    }
};

subtest create_and_update => sub {
    $rrd->create;
    ok -f "$rrd_dir/localhost/test___y_uuki.rrd";

    `rm -fr tmp/*`;
};
