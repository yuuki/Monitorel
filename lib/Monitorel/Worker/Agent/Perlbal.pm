package Monitorel::Worker::Agent::Perlbal;
use strict;
use warnings;
use parent qw(Monitorel::Worker);

use Carp qw(croak);
use Net::Telnet;

use constant DEFAULT_PORT => 60000;

my $STAT_NAMES = [ qw(
    Requests
    Uptime
    Utime
    Stime
    CurFd
    MaxFd
) ];

sub proc {
    my ($class, $args) = @_;

    my $hostname = $args->{host}  // croak "host key must not be empty";
    my $stats    = $args->{stats} // croak "stats key must not be empty";
    my $port     = $args->{port}  || DEFAULT_PORT;

    my $all_stat_to_value = _perlbal_stat_to_value($hostname, $port);
    +{ map { $_ => $all_stat_to_value->{$_} } @$stats };
}

sub _perlbal_stat_to_value {
    my ($hostname, $port) = @_;

    my $lines = _perlbal_response($hostname, $port)
        || croak "no response";

    my $kv = {};
    for (@$lines) {
        chomp;
        next if (!$_ or $_ eq '.');
        my ($k, $v) = _line_to_stat_to_value($_);
        $kv->{$k}   = $v;
    }

    $kv;
}

sub _perlbal_response {
    my ($hostname, $port) = @_;

    my $telnet = Net::Telnet->new(
        Host    => $hostname,
        Port    => $port,
        Timeout => 10,
        Prompt  => '/\.$/',
    );

    my @response_fd     = $telnet->cmd(String => 'fd',     Prompt => '/\.$/', Timeout => 10);
    my @response_proc   = $telnet->cmd(String => 'proc',   Prompt => '/\.$/', Timeout => 10);
    my @response_uptime = $telnet->cmd(String => 'uptime', Prompt => '/\.$/', Timeout => 10);

    $telnet->close;

    # remove line only \n
    shift @response_proc;
    shift @response_uptime;

    [ (@response_fd, @response_proc, @response_uptime) ];
}

sub _line_to_stat_to_value {
    my $line = shift;

    my ($stat, $value) = split(' ', $line);
    if ($stat =~ /(.*):$/) {
        $stat = $1;
    }
    if    ($stat eq 'stime' ) { $stat = "Stime"    }
    elsif ($stat eq 'utime' ) { $stat = "Utime"    }
    elsif ($stat eq 'reqs'  ) { $stat = "Requests" }
    elsif ($stat eq 'cur'   ) { $stat = "CurFd"    }
    elsif ($stat eq 'max'   ) { $stat = "MaxFd"    }
    elsif ($stat eq 'uptime') { $stat = "Uptime"   }

    return ($stat, $value);
}

1;
__END__
