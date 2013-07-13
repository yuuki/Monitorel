package Monitorel::Worker::Dequeue::TheSchwartz;
use strict;
use warnings;
use parent qw(Monitorel::Worker::Dequeue);

use Module::Load;
use Monitorel::TheSchwartz;

sub dequeue {
    my $class   = shift;
    my $workers = shift;

    #TODO cache
    my $client = Monitorel::TheSchwartz->new;

    my $max = 100;
    my $delay = 5;

    for my $worker (@$workers) {
        load $worker or warn $@;
        $worker->can('work') or die "cannot ${_}->work";
        $client->can_do($worker);
    }

    my $count = 0;
    while ($count < $max) {
        if ($client->work_once) {
            $count++;
        }
        else {
            sleep $delay;
        }
    }
}

1;
