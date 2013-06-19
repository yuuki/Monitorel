package Monitorel::Worker::Agent::Test;
use strict;
use warnings;

sub proc {
    my ($class, $args) = @_;
    return +{
        response_num => 1000,
        total_time   => 12345678,
    };
}

1;
