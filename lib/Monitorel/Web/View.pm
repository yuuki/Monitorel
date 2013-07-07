package Monitorel::Web::View;
use strict;
use warnings;
use Carp ();
use File::Spec ();

use Text::Xslate;
use Monitorel::Web::ViewFunctions;

# setup view class
sub make_instance {
    my ($class, $context) = @_;
    Carp::croak("Usage: Monitorel::View->make_instance(\$context_class)") if @_!=2;

    my $view_conf = $context->config->{'Text::Xslate'} || +{};
    unless (exists $view_conf->{path}) {
        $view_conf->{path} = [ File::Spec->catdir($context->base_dir(), 'templates') ];
    }
    my $view = Text::Xslate->new(+{
        'syntax'   => 'TTerse',
        'module'   => [qw(
            Text::Xslate::Bridge::Star
            Monitorel::Web::ViewFunctions
        )],
        'function' => {
        },
        ($context->debug_mode ? ( warn_handler => sub {
            Text::Xslate->print( # print method escape html automatically
                '[[', @_, ']]',
            );
        } ) : () ),
        %$view_conf
    });
    return $view;
}

1;
