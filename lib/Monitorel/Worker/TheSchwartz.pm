package Monitorel::Worker::TheSchwartz;
use strict;
use warnings;
use parent qw(TheSchwartz::Worker);

use Log::Minimal;
use Try::Tiny;

use Monitorel::Worker;

sub max_retries { 1 }

sub work {
    my $class = shift;
    my $job   = shift;

    local $Log::Minimal::PRINT = sub {
        my ($time, $type, $message, $trace, $raw_message) = @_;
        open(my $fh, ">>", "log/worker.log")
            or die "cannot open worker.log";
        print $fh "$time [$type] $message at $trace\n";
    };

    try {
        Monitorel::Worker->fetch_and_store_stat($job->arg);
    } catch {
        warnf "Failed to fetch_and_store_stat: $_";
        return $job->failed($_, 1);
    };
    return $job->completed;
}

1;
