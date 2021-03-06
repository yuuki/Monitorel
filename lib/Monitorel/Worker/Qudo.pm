package Monitorel::Worker::Qudo;
use strict;
use warnings;
use parent qw(Qudo::Worker);

use Log::Minimal;
use Try::Tiny;

use Monitorel::Worker;

sub max_retries { 1 }

sub work {
    my $class = shift;
    my $job   = shift;

    try {
        Monitorel::Worker->fetch_and_store_stat($job->arg);
    } catch {
        warnf "Failed to fetch_and_store_stat: $_";
        return $job->failed($_, 1);
    };
    return $job->completed;
}

1;
