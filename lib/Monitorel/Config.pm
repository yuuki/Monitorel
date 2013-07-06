package Monitorel::Config;
use strict;
use warnings;

use Config::ENV 'PLACK_ENV', default => 'development';
use Path::Class qw(dir);

my $root = dir(__FILE__)->parent->parent->parent;
sub root { $root }

common +{
    rrd_dir => root->subdir('rrd')->stringify,
};

config production  => +{
    'worker.dsn' => [
        "dbi:mysql:dbname=monitorel_worker;host=localhost",
        'nobody',
        'nobody',
    ],
    eval { load root->file('config/deployment.pl')->stringify }
};

config development => +{
    'worker.dsn' => [
        "dbi:mysql:dbname=monitorel_worker;host=localhost",
        'nobody',
        'nobody',
    ],

    rrd_dir => root->subdir('rrd')->stringify . '/development',
    TheSchwartz => {
        dbname => 'monitorel_worker',
        user => '',
        passwd => '',
    },
    Qudo => {
        dbname => 'monitorel_worker',
        default_hooks => ['Qudo::Hook::Serialize::JSON'],
        work_delay    => 5,
    },
    eval { load root->file('config/development.pl')->stringify }
};

config test        => +{
    'worker.dsn' => [
        "dbi:mysql:dbname=test_monitorel_worker;host=localhost",
        'nobody',
        'nobody',
    ],

    rrd_dir => root->subdir('rrd')->stringify . '/test',
    TheSchwartz => {
        dbname => 'test_monitorel_worker',
        user => '',
        passwd => '',
    },
    Qudo => {
        dbname => 'test_monitorel_worker',
        default_hooks => ['Qudo::Hook::Serialize::JSON'],
        work_delay    => 5,
    },
    eval { load root->file('config/test.pl')->stringify }
};

1;
