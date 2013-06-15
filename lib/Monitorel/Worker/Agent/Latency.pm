package Monitorel::Worker::Agent::Latency;
use strict;
use warnings;
use parent qw(Monitorel::Worker);

use Carp qw(croak);
use URI;
use LWP::UserAgent;
use Time::HiRes;


sub proc {
    my ($class, $args) = @_;

    $args->{url} or croak "url required";
    my $uri = URI->new($args->{url});
    return if $uri->scheme ne 'http';

    my $usec = latency_by_url($uri->as_string);
    my $url_to_usec = +{ $args->{url} => $usec };
}

sub latency_by_url {
    my $url = shift;

    my $ua = LWP::UserAgent->new;
    $ua->agent('Web Latency Agent 0.1');
    $ua->timeout(10);

    my $start_time = Time::HiRes::time;

    my $response = $ua->get($url);
    $response->is_error and croak "status code is 4xx or 5xx $url";

    my $end_time = Time::HiRes::time;

    my $usec = int(($end_time - $start_time) * 1000000);
}

1;
__END__
