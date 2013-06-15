package Monitorel::Worker::Agent::Perlbal;
use strict;
use warnings;
use parent qw(Monitorel::Worker);

use Carp qw(croak);
use Net::Telnet;

use constant {
    DEFAULT_PORT => 60000,
    STAT_NAMES   => [qw(
        Requests
        Uptime
        Utime
        Stime
        CurFd
        MaxFd
    )],
};

sub proc {
    my ($class, $args) = @_;

    my $hostname = $args->{host}  or croak "host required";
    my $stats    = $args->{stats} || STAT_NAMES;
    my $port     = $args->{port}  || DEFAULT_PORT;

    my $lines = perlbal_response($hostname, $port)
        or croak "no response";

    my $stat_to_value = {};
    for my $line (@$lines) {
        chomp $line;
        next if (!$line or $line eq '.');

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

        $stat_to_value->{$stat} = $value;
    }

    return +{ map { $_ => $stat_to_value->{$_} } @$stats };
}

sub perlbal_response {
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

    return [ (@response_fd, @response_proc, @response_uptime) ];
}

1;
__END__
