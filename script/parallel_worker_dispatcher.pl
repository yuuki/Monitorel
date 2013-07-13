#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;
use Module::Load;

$ENV{PLACK_ENV} ||= 'development';

use Monitorel::Worker::TheSchwartz;
use Monitorel::Worker::Qudo;

my $message_queue = 'TheSchwartz';
GetOptions(
    'help'            => \my $help,
    'message_queue=s' => \$message_queue,
    'max_workers'     => \my $max_workers,
    'version'         => \my $version,
) or pod2usage(0);
pod2usage(1) if $help;
unless ($message_queue eq 'TheSchwartz'
        || $message_queue eq 'Qudo') {
    pod2usage(1);
}

&main;exit;

sub main {
    my $dequeue_class = "Monitorel::Worker::Dequeue::$message_queue";
    load $dequeue_class;

    $dequeue_class->run(["Monitorel::Worker::$message_queue"], $max_workers);
}

=head1 NAME

parallel_worker_dispatcher.pl - Dispatch parallelly Monitorel::Worker jobs

=head1 SYNOPSIS

    % parallel_worker_dispatcher.pl

        --message_queue=theschwartz   basic flavour (default)
        --flavor=Lite    Amon2::Lite flavour (need to install)
        --flavor=Minimum minimalistic flavour for benchmarking

        --vc=Git         setup the git repository (default)

        --list-flavors (or -l) Shows the list of flavors installed

        --help   Show this help
