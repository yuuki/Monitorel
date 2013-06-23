package Monitorel::Worker::Store::RRD::Path;
use utf8;
use strict;
use warnings;

use Cwd qw(getcwd);
use Carp qw(croak);
use Path::Class qw(dir);

use Monitorel::Config;

use Exporter::Lite;
our @EXPORT_OK = qw(get_path get_absolute_path);

sub get_path {
    my ($path_args) = @_;
    croak("path_args is not ARRAY") if ref($path_args) ne 'ARRAY';

    my $dir_path = dir(shift @$path_args);
    return $dir_path->file(join('___', @$path_args) . '.rrd');
}

sub get_absolute_path {
    my $args = shift;
    my $rrd_dir = Monitorel::Config->param('rrd_dir');
    croak("args is not ARRAY") if ref($args) ne 'ARRAY';
    croak("rrd_dir is not directory") if not $rrd_dir || not -d $rrd_dir;

    my $rel_path = get_path($args);
    return dir($rrd_dir)->file($rel_path)->absolute;
}

1;
__END__
