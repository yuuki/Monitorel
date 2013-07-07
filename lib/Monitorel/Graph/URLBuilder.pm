package Monitorel::Graph::URLBuidler;
use strict;
use warnings;

use Carp qw(croak);

use constant {
    COLOR_PALETTE   => [qw(
        @0000ff @ff0000 @00ff00 @ff00ff @999900 @7777FF @883333 @22aa22 @FF3333
    )],
    COLOR_NUM => 9,
};

sub graph_image_tag {
    my $class = shift;
    my $url = $class->graph_url_for(@_);
    return "<img src='$url'>";
}

sub graph_url_for {
    my ($class, $args, $global_option) = @_;

    $global_option ||= {};
    croak 'global option must be Hashref' if ref($global_option) ne 'HASH';

    my $i = 0;
    my $graphs = [];
    while (my ($inst, $param) = splice(@$args, 0, 2)) {
        croak "param must be Hashref: $inst" if ref($param) ne 'HASH';
        my $str = "";

        if (my $code = $class->can("_build_$inst")) {
            $str .= $code->($inst, $param);
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

sub _build_def {
    my ($inst, $param) = @_;

    my $tag   = defined $param->{tag} ? $param->{tag} : '';
    my $label = defined $param->{label} ? $param->{label} : '';
    my $path  = join ',', $param->{object}, $tag, $label;
    my $type  = uc($param->{type} || 'AVERAGE');
    return sprintf("%s:%s:::=path:%s:value:%s", $inst, $param->{vname}, $path, $type);
}

sub _build_cdef {
    my ($inst, $param) = @_;
    return sprintf("%s:%s:::=%s", $inst, $param->{vname}, $param->{value});
}
*_build_vdef = \&_build_cdef;

sub _build_line {
    my ($inst, $param, $i) = @_;

    my $width  = $param->{width} || 1;
    my $value  = $param->{value} or croak "requried $inst 'value' key";
    my $color  = $param->{color} || COLOR_PALETTE->[($i++ % COLOR_NUM)];
    my $legend = $param->{legend} || $value;
    my $stack  = defined $param->{stack} && $param->{stack} ? ':STACK' : '';
    return sprintf("%s%d:%s:::%s:%s%s", $inst, $width, $value, $color, $legend, $stack);
}

sub _build_area {
    my ($inst, $param, $i) = @_;

    my $value  = $param->{value} or croak "requried $inst 'value' key";
    my $color  = $param->{color} || COLOR_PALETTE->[($i++ % COLOR_NUM)];
    my $legend = $param->{legend} || $value;
    my $stack  = defined($param->{stack}) && $param->{stack} ? ':STACK' : '';
    return sprintf("%s:%s:::%s:%s%s", $inst, $value, $color, $legend, $stack);
}

sub _build_vrule {
    my ($inst, $param, $i) = @_;

    my $value  = $param->{value} or croak "requried $inst 'value' key";
    my $color  = $param->{color} || COLOR_PALETTE->[($i++ % COLOR_NUM)];
    my $legend = $param->{legend} || $value;
    return sprintf("%s:%s:::%s%s", $inst, $value, $color, $legend);
}
*_build_hrule = \&_build_vrule;

1;
