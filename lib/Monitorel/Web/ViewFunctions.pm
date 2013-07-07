package Monitorel::Web::ViewFunctions;
use strict;
use warnings;
use Module::Functions;
use File::Spec;

use Exporter::Lite;
our @EXPORT = get_public_functions();

use Monitorel::Graph::URLBuilder;

sub commify {
    local $_  = shift;
    1 while s/((?:\A|[^.0-9])[-+]?\d+)(\d{3})/$1,$2/s;
    return $_;
}

sub c { Amon2->context() }
sub uri_with { Amon2->context()->req->uri_with(@_) }
sub uri_for { Amon2->context()->uri_for(@_) }

sub graph_image_tag {
    Monitorel::Graph::URLBuilder->graph_image_tag(@_);
}

sub graph_url_for {
    Monitorel::Graph::URLBuilder->graph_url_for(@_);
}

{
    my %static_file_cache;
    sub static_file {
        my $fname = shift;
        my $c = Amon2->context;
        if (not exists $static_file_cache{$fname}) {
            my $fullpath = File::Spec->catfile($c->base_dir(), $fname);
            $static_file_cache{$fname} = (stat $fullpath)[9];
        }
        return $c->uri_for(
            $fname, {
                't' => $static_file_cache{$fname} || 0
            }
        );
    }
}

1;
