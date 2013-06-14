package Monitorel::Worker;
use strict;
use warnings;
use parent qw(TheSchwartz::Worker);

use Try::Tiny;

use Monitorel::Worker::Store::RRD;


sub max_retries { 1 }

sub proc {
    die 'should be implemented by subclass';
}

sub work {
    my $class = shift;
    my $job   = shift;

    my $stat_to_value;
    try {
        $job->arg->{host} ||= $job->arg->{fqdn};
        $stat_to_value = $class->proc($job->arg);
    } catch {
        return $job->failed($_, 1);
    };

    for my $stat (keys %$stat_to_value) {
        my $rrd = Monitorel::Worker::Store::RRD->new($job->arg, $stat);
        $rrd->create;
        $rrd->update(time, $stat_to_value->{$stat} || 0);
    }
    return $job->completed;
}

1;
