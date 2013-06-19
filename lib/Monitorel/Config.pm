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
    eval { load root->file('config/deployment.pl')->stringify }
};

config development => +{
    TheSchwartz => {
        dbname => 'theschwartz',
        user => '',
        passwd => '',
    },
    Qudo => {
        dbname => 'qudo',
        default_hooks => ['Qudo::Hook::Serialize::JSON'],
        work_delay    => 5,
    },
    eval { load root->file('config/development.pl')->stringify }
};

config test        => +{
    TheSchwartz => {
        dbname => 'test_theschwartz',
        user => '',
        passwd => '',
    },
    Qudo => {
        dbname => 'test_qudo',
        default_hooks => ['Qudo::Hook::Serialize::JSON'],
        work_delay    => 5,
    },
    eval { load root->file('config/test.pl')->stringify }
};

1;
