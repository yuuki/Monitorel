use strict;
use utf8;
use File::Spec;
use File::Basename;
use lib File::Spec->catdir(dirname(__FILE__), 'lib');
use Plack::Builder;

use Monitorel::Config;
use Monitorel::Web;

builder {
    enable 'ReverseProxy';

    enable 'Static',
        path => qr{^(?:/static/)},
        root => File::Spec->catdir(dirname(__FILE__), '../');
    enable 'Static',
        path => qr{^(?:/robots\.txt|/favicon\.ico)$},
        root => File::Spec->catdir(dirname(__FILE__), '../static');

    enable 'Runtime';
    enable 'Head';

    enable 'AxsLog', (
        ltsv => 1,
        response_time => 1
    ) if Monitorel::Config->env eq 'production';

    enable 'Log::Minimal', loglevel => 'INFO', autodump => 1;

    Monitorel::Web->to_app();
};
