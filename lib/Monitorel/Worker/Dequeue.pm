package Monitorel::Worker::Dequeue;
use strict;
use warnings;

use Parallel::Prefork;

sub run {
    my ($class, $workers, $max_worker_num) = @_;

    $max_worker_num ||= 4;

    my $pm = Parallel::Prefork->new({
        max_workers  => $max_worker_num,
        trap_signals => {
            TERM => 'TERM',
            HUP  => 'TERM',
            INT  => 'TERM',
            USR1 => undef,
        }
    });

    while ($pm->signal_received !~ /^(?:TERM|INT)$/) {
        $pm->start and next;

        $class->dequeue($workers);

        $pm->finish;
    }

    $pm->wait_all_children;
}

1;
