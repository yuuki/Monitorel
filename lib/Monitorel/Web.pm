package Monitorel::Web;
use strict;
use warnings;

use Amon2::Lite;
use RRDTool::Rawish;
use Try::Tiny;

use Monitorel::GraphURLParser;

get '/rrdtool' => sub {
    my ($c) = @_;
    my $params = $c->req->parameters;
    my $notation = $params->{s}
        or die 403;

    my $parser = Monitorel::GraphURLParser->new;
    my ($commands, $option);
    try {
        ($commands, $option) = $parser->parse($notation);
    } catch {
        die 403;
    };

    my $image = RRDTool::Rawish->new->graph($commands, $option);

    my $res = $c->create_response(200);
    $res->content_type('image/png');
    $res->content($image);
    return $res;
};

1;
