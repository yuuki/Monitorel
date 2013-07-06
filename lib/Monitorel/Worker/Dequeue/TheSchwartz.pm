package Monitorel::Worker::Dequeue::TheSchwartz;
use strict;
use warnings;
use parent qw(Monitorel::Worker::Dequeue);

use Data::ObjectDriver::Driver::DBI;
use Module::Load;
use TheSchwartz;

use Monitorel::Scope::Container::DBI;

sub dequeue {
    my $class   = shift;
    my $workers = shift;

    my $dbh = Monitorel::Scope::Container::DBI->connect;
    my $driver = Data::ObjectDriver::Driver::DBI->new(dbh => $dbh);
    my $client = TheSchwartz->new(databases => [{ driver => $driver }]);

    my $max = 100;
    my $delay = 5;

    for my $worker (@$workers) {
        load $worker or warn $@;
        $worker->can('work') or die "cannot ${_}->work";
        $client->can_do($_);
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
