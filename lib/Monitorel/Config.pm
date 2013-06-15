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

config production  => {
    eval { load root->file('config/deployment.pl')->stringify }
};

config development => {
    eval { load root->file('config/development.pl')->stringify }
};

config test        => {
    eval { load root->file('config/test.pl')->stringify }
};

1;
