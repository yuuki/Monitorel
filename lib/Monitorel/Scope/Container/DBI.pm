package Monitorel::Scope::Container::DBI;
use strict;
use warnings;
use parent qw(Scope::Container::DBI);

use Monitorel::Config;

sub connect {
    my $class = shift;
    $class->SUPER::connect(@{Monitorel::Config->param('worker.dsn')},
    {
        RaiseError => 1,
        mysql_connect_timeout => 4,
        mysql_enable_utf8 => 1,
    });
}

1;
