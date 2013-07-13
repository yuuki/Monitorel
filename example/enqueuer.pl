#!/usr/bin/env perl
use strict;
use warnings;

$ENV{PLACK_ENV} ||= 'development';

use TheSchwartz::Simple;
use Monitorel::Scope::Container::DBI;


my $dbh = Monitorel::Scope::Container::DBI->connect;
my $client = TheSchwartz::Simple->new([ $dbh ]);

my $job_id = $client->insert('Monitorel::Worker::TheSchwartz', {
    agent => 'Nginx',
    fqdn  => '192.168.33.10',
    stats => [qw(ActiveConnections Requests)],
    port  => 8090,
    tag   => 'nginx',
    type  => {
        ActiveConnections => 'gauge',
        Requests          => 'gauge',
    }
});
