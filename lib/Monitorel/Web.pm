package Monitorel::Web;
use strict;
use warnings;
use parent qw(Monitorel Amon2::Web);

use Log::Minimal;
use RRDTool::Rawish;
use Scalar::Util ();
use Try::Tiny;

use Monitorel::Web::Dispatcher;

sub dispatch {
    my $c = shift;
    my $res;
    try {
        $res = Monitorel::Web::Dispatcher->dispatch($c);
    } catch {
        my $e = $_;

        if (Scalar::Util::blessed($e) && $e->isa('Monitorel::Error')) {
            if (defined $e->{message}) {
                $res = $c->create_response;
                $res->content($e->{message});
                $res->content_type('text/plain; charset=utf-8');
            }
            else {
                $res = $c->render('error.tt' => {
                    status  => $e->{status},
                    message => $e->{message},
                });
            };

            $res->status($e->{status});
            $res->header('X-Error-Message' => $e->{message}) if $e->{message};

            if (defined $e->{location}) {
                $res->header('Location' => $e->{location});
            }
        }
        else {
            critf "%s", $e;

            $res = $c->render('error.tt' => {
                status  => '500',
                message => 'Internal Server Error',
            });
            $res->header('X-Error-Message' => $e);
            $res->status(500);
        }
    };
    return $res;
}

# load plugins
__PACKAGE__->load_plugins(
    # 'Web::FillInFormLite',
    'Web::CSRFDefender' => {
        post_only => 1,
    },
);

# setup view
use Monitorel::Web::View;
{
    my $view = Monitorel::Web::View->make_instance(__PACKAGE__);
    sub create_view { $view }
}

# for your security
__PACKAGE__->add_trigger(
    AFTER_DISPATCH => sub {
        my ( $c, $res ) = @_;

        # http://blogs.msdn.com/b/ie/archive/2008/07/02/ie8-security-part-v-comprehensive-protection.aspx
        $res->header( 'X-Content-Type-Options' => 'nosniff' );

        # http://blog.mozilla.com/security/2010/09/08/x-frame-options/
        $res->header( 'X-Frame-Options' => 'DENY' );

        # Cache control.
        $res->header( 'Cache-Control' => 'private' );
    },
);

__PACKAGE__->add_trigger(
    BEFORE_DISPATCH => sub {
        my ( $c ) = @_;
        # ...
        return;
    },
);

sub image {
    my ($self, $format, $image) = @_;

    $format =~ /jpg|jpeg|png|svg|eps|pdf/
        or $self->error("invalid image format $format");

    my $res = $self->create_response(200);
    $res->content_type("image/$format");
    $res->content($image);
    return $res;
}

sub error {
    my ($self, $status, $message, %opts) = @_;

    critf "message:%s", $message;

    Monitorel::Error->throw(
        message => $message,
        status  => $status,
        %opts
    );
}

1;
