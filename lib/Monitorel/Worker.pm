package Monitorel::Worker;
use strict;
use warnings;

use Carp qw(croak);
use Module::Load qw(load);

use Monitorel::Worker::Store::RRD;


sub fetch_and_store_stat {
    my ($class, $args) = @_;

    my $agent = $args->{agent} or croak 'agent required';
    $args->{host} ||= $args->{fqdn} or croak 'fqdn required';

    my $agent_class = "Monitorel::Worker::Agent::$agent";
    load $agent_class;

    my $stat_to_value = $agent_class->proc($args);

    for my $stat (keys %$stat_to_value) {
        my $rrd = Monitorel::Worker::Store::RRD->new($args, $stat);
        $rrd->create;
        $rrd->update(time, $stat_to_value->{$stat} || 0);
    }
}

1;
