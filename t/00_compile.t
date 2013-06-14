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
        Monitorel::Worker::Agent::Memcached
        Monitorel::Worker::Agent::Munin
        Monitorel::Worker::Agent::MySQL
        Monitorel::Worker::Agent::Nginx
        Monitorel::Worker::Agent::Perlbal
        Monitorel::Worker::Agent::Plack
        Monitorel::Worker::Agent::Redis
        Monitorel::Worker::Agent::Schwartz
        Monitorel::Worker::Agent::SNMP
    )
}

done_testing;
