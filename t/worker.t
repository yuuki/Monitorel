use t::monitoreltest;

use Test::Mock::Guard qw(mock_guard);

use Monitorel::Config;
use Monitorel::Worker;
use Monitorel::Worker::Store::RRD::Path;


subtest 'fetch_and_store_stat' => sub {
    my $rrd_dir = Monitorel::Config->param('rrd_dir');
    Monitorel::Worker::Store::RRD::Path->set_rrddir($rrd_dir);

    my $stat_to_value = { TotalAccesses => 10000, BusyWorkers => 200 };
    my $mock = mock_guard 'Monitorel::Worker::Agent::Apache' => {
        proc => sub {
            return $stat_to_value;
        },
    };

    Monitorel::Worker->fetch_and_store_stat({
        agent => 'Apache',
        fqdn  => 'localhost',
        tag   => 'apache',
    });

    ok -f "$rrd_dir/localhost/apache___TotalAccesses.rrd";
    ok -f "$rrd_dir/localhost/apache___BusyWorkers.rrd";

    `rm -fr $rrd_dir/localhost`;

};
