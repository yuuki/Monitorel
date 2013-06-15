package Monitorel::GraphURLParser;
use utf8;
use strict;
use warnings;

use Carp qw(croak);
use List::MoreUtils;
use Monitorel::Worker::Store::RRD::Path;


my $OP = qr/\+|\/|%|\*/;
my $MARK = qr/-|_|\.|!|~|\*|'|"/;
my $CHAR = qr/[A-Za-z0-9]|$MARK/;
my $NAME = qr/($CHAR)+/;
my $OPTION = qr/($CHAR|,|=|#|:|$OP|\s|@|\\)+/;
my $PATH = qr/($CHAR|,)+/;
my $INSTRUCTION = qr/(def|cdef|vdef|line[1-9]?|area|hrule|vrule|print|gprint|comment|tick|shift|textalign)/;
my $GRAPH = qr/($INSTRUCTION($NAME)?:::$OPTION)/;


sub new {
    my $class = shift;
    return bless { hosts => [] }, $class;
}


sub parse {
    my $self = shift;
    my $body = shift;

    my $hash = $self->to_hash($body);
    my ($commands, $option) = $self->to_command($hash);
    return ($commands, $option, $hash->{hosts});
}


sub hosts {
    return $_[0]->{hosts};
}

sub _add_host {
    my ($self, $host) = @_;
    if (List::MoreUtils::none {$_ eq $host} @{$self->{hosts}}) {
        push @{$self->{hosts}}, $host;
    }
}


sub to_hash {
    my $self = shift;
    my $body = shift;
    my $hash = { graphs => [], global_option => undef };

    unless ($body =~ /^\[(?<graphs>.+?)(!(?<option>$OPTION))?\]$/) {
        die "syntax error: mismatch with [<graphs>(|<option>)], $body";
    }

    $hash->{global_option} = $+{option};

    if ($+{graphs} =~ /,$/) {
        die "syntax error: mismatch with <graphs>, $+{graphs}";
    }
    if (my @graphs = ($+{graphs} =~ /\((.+?)\)/g)) {
        for my $graph (@graphs) {
            my $h = $self->_graph_to_hash($graph);
            push $hash->{graphs}, $h;
        }
    }
    else {
        my $h = $self->_graph_to_hash($+{graph});
        push $hash->{graphs}, $h;
    }

    return $hash;
}


sub _graph_to_hash {
    my $self = shift;
    my $graph = shift;

    unless ($graph =~ /((?<inst>$INSTRUCTION):(?<name>$NAME)?:::(?<option>$OPTION))/) {
        die "syntax error: mismatch with <graph> $graph";
    }

    my ($inst, $name, $option) = ($+{inst}, $+{name}, $+{option});
    if ($inst eq 'def') {
        if ($option =~ /^=path:(?<object>$NAME)(,(?<tag>$NAME))?(,(?<label>$NAME))?:/) {
            #XXX Duplicate code with Monitorel::Engine::Graph
            my $object  = $+{object};
            my $tag     = $+{tag}   || '_default';
            my $label   = $+{label} || 'loadavg5';
            my $rrdfile = Monitorel::Worker::Store::RRD::Path::get_relative_path([
                $object, $tag, $label
            ])->stringify;
            $option =~ s/^=path:$PATH:/=$rrdfile:/;

            $self->_add_host($object);
        }
        elsif ($option =~ /^=(?<host>$NAME)__/) {
            $self->_add_host($+{host});
        }
    }
    elsif ($inst =~ /^vrule|hrule|line|area|tick$/) {
        $option =~ s/^@/#/;
    }
    return {instruction => $inst, name => $name, option => $option};
}


sub to_command {
    my $self = shift;
    my $hash = shift;

    #XXX syntax check for global option
    my $goption = {};
    if ($hash->{global_option}) {
        for (split(/,/, $hash->{global_option})) {
            my ($k, $v) = split('=', $_);
            $goption->{$k} = $v;
        }
    }

    #XXX duplciate Monitorel::Engine::Graph
    my $global_options = {
        '--imgformat' => $goption->{imgformat} || $goption->{i}  || 'PNG',
        '--width'     => $goption->{width}     || $goption->{w}  || 480,
        '--height'    => $goption->{height}    || $goption->{h}  || 300,
        '--start'     => $goption->{start}     || $goption->{s}  || 'now-1d',
        '--end'       => $goption->{end}       || $goption->{e}  || 'now',
        '--period'    => $goption->{period}    || $goption->{p}  || undef,
        '--unit'      => $goption->{unit}      || $goption->{u}  || undef,
        '--ulimit'    => $goption->{ulimit}    || $goption->{ul} || undef,
        '--llimit'    => $goption->{llimit}    || $goption->{ll} || undef,
        '--rigid'     => $goption->{rigid}     || $goption->{r}  || 1,
        '--hrule'     => $goption->{hrule}     || $goption->{hr} || undef,
    };
    # delete option if undef
    for (keys %$global_options) {
        unless (defined $global_options->{$_}) {
            delete $global_options->{$_};
        }
    }

    my $commands = [ map {
        uc($_->{instruction}) . ':' . $_->{name} . $_->{option}
    } (@{$hash->{graphs}}) ];

    return $commands, $global_options;
}


1;
