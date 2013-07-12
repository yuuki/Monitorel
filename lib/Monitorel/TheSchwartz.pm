package Monitorel::TheSchwartz;
use strict;
use warnings;
use parent qw(TheSchwartz);

use Monitorel::Config;

sub new {
    my $class  = shift;
    my $config = Monitorel::Config->param('worker.dsn');
    $class->SUPER::new(databases => [{
        dsn  => $config->[0],
        user => $config->[1],
        pass => $config->[2],
    }]);
}

1;
