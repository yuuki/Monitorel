package t::monitoreltest;
use warnings;
use lib lib => 't/lib';

BEGIN {
    unless ($ENV{PLACK_ENV}) {
        $ENV{PLACK_ENV} = 'test';
    }
    if ($ENV{PLACK_ENV} eq 'production') {
        die "Don't run a test script on production environment";
    }
}

use Exporter::Lite ();

sub import {
    strict->import;
    warnings->import;
    utf8->import;

    my ($class, @opts) = @_;
    my ($pkg, $file) = caller;
    my $code = qq[
        package $pkg;
        use Test::More;
        use lib 'lib' => 't/lib';

        END {
            done_testing;
        }
    ];

    eval $code;
    die $@ if $@;

    @_ = ($class, @opts);
    goto &Exporter::Lite::import;
}

1;
