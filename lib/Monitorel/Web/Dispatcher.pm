package Monitorel::Web::Dispatcher;
use strict;
use warnings;

use Monitorel::Error;
use Monitorel::Graph::URLParser;

use Amon2::Web::Dispatcher::Lite;
use Log::Minimal;
use RRDTool::Rawish;
use Try::Tiny;

any '/' => sub {
    my ($c) = @_;
    $c->render('index.tt');
};

get '/samples' => sub {
    my ($c) = @_;
    $c->render('samples.tt');
};

get '/rrdtool' => sub {
    my ($c) = @_;
    my $params = $c->req->parameters;
    my $notation = $params->{s}
        or $c->error(403 => "required query param 's'");

    my $parser = Monitorel::Graph::URLParser->new;
    my ($commands, $option);
    try {
        ($commands, $option) = $parser->parse($notation);
    } catch {
        warnf $_;
        $c->error(403 => $_);
    };

    my $rrd = RRDTool::Rawish->new;
    my $image = $rrd->graph('-', $commands, $option);
    return $c->error(404 => $rrd->errstr) if $rrd->errstr;

    return $c->image(png => $image);
};

1;
