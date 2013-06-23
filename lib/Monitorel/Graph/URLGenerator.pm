package Monitorel::Graph::URLGenerator;
use strict;
use warnings;

use Carp qw(croak);

use Exporter::Lite;
our @EXPORT = qw(
    graph_image_tag
    graph_url_for
);

use constant {
    COLOR_PALETTE   => [qw(
        @0000ff @ff0000 @00ff00 @ff00ff @999900 @7777FF @883333 @22aa22 @FF3333
    )],
    COLOR_NUM => 9,
};

sub graph_image_tag {
    my $url = graph_url_for(@_);
    return "<img src='$url'>";
}

sub graph_url_for {
    my ($args, $global_option) = @_;

    $global_option ||= {};
    croak 'global option must be Hashref' if ref($global_option) ne 'HASH';

    my $i = 0;
    my $graphs = [];
    while (my ($inst, $param) = splice(@$args, 0, 2)) {
        croak "param must be Hashref: $inst" if ref($param) ne 'HASH';
        my $str = "";

        if ($inst eq 'def') {
            my $tag   = defined $param->{tag} ? $param->{tag} : '';
            my $label = defined $param->{label} ? $param->{label} : '';
            my $path  = join ',', $param->{object}, $tag, $label;
            my $type  =  uc($param->{type} || 'AVERAGE');
            $str .= sprintf("%s:%s:::=path:%s:value:%s", $inst, $param->{vname}, $path, $type);
        }
        elsif ($inst eq 'cdef' || $inst eq 'vdef') {
            $str .= sprintf("%s:%s:::=%s", $inst, $param->{vname}, $param->{value});
        }
        elsif ($inst eq 'line') {
            my $width  = $param->{width} || 1;
            my $value  = $param->{value} or croak "requried $inst 'value' key";
            my $color  = $param->{color} || COLOR_PALETTE->[($i++ % COLOR_NUM)];
            my $legend = $param->{legend} || $value;
            my $stack  = exists($param->{stack}) && $param->{stack} ? ':STACK' : '';
            $str .= sprintf("%s%d:%s:::%s:%s%s", $inst, $width, $value, $color, $legend, $stack);
        }
        elsif ($inst eq 'area') {
            my $value  = $param->{value} or croak "requried $inst 'value' key";
            my $color  = $param->{color} || COLOR_PALETTE->[($i++ % COLOR_NUM)];
            my $legend = $param->{legend} || $value;
            my $stack  = exists($param->{stack}) && $param->{stack} ? ':STACK' : '';
            $str .= sprintf("%s:%s:::%s:%s%s", $inst, $value, $color, $legend, $stack);
        }
        elsif ($inst eq 'vrule' || $inst eq 'hrule') {
            my $value  = $param->{value} or croak "requried $inst 'value' key";
            my $color  = $param->{color} || COLOR_PALETTE->[($i++ % COLOR_NUM)];
            my $legend = $param->{legend} || $value;
            $str .= sprintf("%s:%s:::%s%s", $inst, $value, $color, $legend);
        }
        else {
            croak "Not supported inst: $inst";
        }

        push @$graphs, "($str)";
    }

    # Global option
    my $option = '';
    if (%$global_option) {
        $option .= '!';
        my @opts = map {
            join('=', $_, $global_option->{$_})
        } sort(keys $global_option);
        $option .= join ',', @opts;
    }

    my $s = join ',', @$graphs;
    return sprintf("/rrdtool?s=[%s%s]", $s, $option);
}

1;
