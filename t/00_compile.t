use strict;
use lib 'lib';

use Test::More;

BEGIN {
    use_ok qw(
        Monitorel::Worker
        Monitorel::Worker::Store
        Monitorel::Worker::Store::RRD
        Monitorel::Worker::Store::RRD::Path
        Monitorel::Worker::Agent::Apache
        Monitorel::Worker::Agent::Latency
        Monitorel::Worker::Agent::MemcachedStat
        Monitorel::Worker::Agent::Munin
        Monitorel::Worker::Agent::MySQLStat
        Monitorel::Worker::Agent::Nginx
        Monitorel::Worker::Agent::Perlbal
        Monitorel::Worker::Agent::Plack
        Monitorel::Worker::Agent::RedisStat
        Monitorel::Worker::Agent::Schwartz
        Monitorel::Worker::Agent::SnmpTarget
    )
}

done_testing;
