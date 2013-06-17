package Monitorel::Worker::Store::RRD;
use utf8;
use strict;
use warnings;

use Carp qw(croak);
use RRDTool::Rawish;
use Try::Tiny;

use parent qw(Monitorel::Worker::Store);

use Monitorel::Worker::Store::RRD::Path qw(get_absolute_path get_relative_path);


sub new {
    my ($class, $args, $stat) = @_;

    my $label = do {
        if (defined $args->{label} and $args->{label}{$stat}) {
            $args->{label}{$stat};
        } else {
            $stat;
        }
    };
    my $path_args = [
        $args->{fqdn},
        $args->{tag} || '_default',
        $label,
    ];
    my $type = uc($args->{type}->{$stat} || 'gauge');

    my $path = get_absolute_path($path_args);
    try {
        $path->dir->mkpath unless -d $path->dir;
    } catch {
        warn $_;
    };

    my $rrd  = RRDTool::Rawish->new( rrdfile => $path->stringify );

    my $self = bless {
        stat => $stat,
        type => $type,
        rrd  => $rrd,
    }, $class;
    return $self;
}

sub create {
    my ($self) = @_;

    my $type = $self->{type};
    my $min  = $self->{type} eq 'DERIVE' ? '0' : 'U';

    try {
        $self->{rrd}->create([
            "DS:value:$type:600:$min:U",
            "RRA:AVERAGE:0.5:1:600",
            "RRA:AVERAGE:0.5:6:700",
            "RRA:AVERAGE:0.5:24:775",
            "RRA:AVERAGE:0.5:288:797",
            "RRA:MAX:0.5:1:600",
            "RRA:MAX:0.5:6:700",
            "RRA:MAX:0.5:24:775",
            "RRA:MAX:0.5:288:797"
        ], {
            "--step"  => "300",
            "--start" => "now-1h",
        });
    } catch {
        warn $_;
    };
    warn $self->{rrd}->errstr if $self->{rrd}->errstr;
}

sub update {
    my ($self, $time, $value) = @_;

    try {
        $self->{rrd}->update([join(':', $time, $value)]);
    } catch {
        warn $_;
    };
    warn $self->{rrd}->errstr if $self->{rrd}->errstr;
}

1;
