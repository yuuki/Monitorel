package Monitorel::Worker::Store::RRD::Path;
use strict;
use warnings;

use Cwd qw(getcwd);
use Carp qw(croak);
use Clone qw(clone);
use Path::Class qw(dir);
use Exporter::Lite;

our @EXPORT_OK = qw(get get_relative_path get_absolute_path);


#XXX want to add Monitorel::Worker::Config interface
our $rrd_dir;
sub set_rrddir{
    my $class = shift;
    $rrd_dir  = $_[0];
}

sub get {
    my ($args) = shift;
    get_absolute_path($args);
}

sub get_relative_path {
    my $path_args = shift;
    croak("path_args is not ARRAY") if ref($path_args) ne 'ARRAY';

    my $args      = clone $path_args;
    my $file_path = dir(shift @$args);

    $file_path    = $file_path->file(join('___', @$args) . '.rrd');
    return $file_path;
}

sub get_absolute_path {
    my $args    = shift;
    croak("args is not ARRAY") if ref($args) ne 'ARRAY';
    croak("rrd_dir is not directory") if not $rrd_dir || not -d $rrd_dir;

    local $rrd_dir = $rrd_dir || getcwd;

    my $rel_path  = get_relative_path($args);

    my $file_path = dir($rrd_dir)->file($rel_path);
    return $file_path;
}

1;
__END__
