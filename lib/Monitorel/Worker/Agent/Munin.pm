package Monitorel::Worker::Agent::Munin;
use strict;
use warnings;
use parent qw(Monitorel::Worker);

use Carp qw(croak);
use IO::Socket;

use constant {
    BUFF_SIZE    => 20000,
    DEFAULT_PORT => 4949,
};

sub proc {
    my ($class, $args) = @_;

    my $hostname = $args->{host}  || croak "host requried";
    my $services = $args->{stats} || croak "stats required";
    my $port     = $args->{port}  || DEFAULT_PORT;

    my $sock = IO::Socket::INET->new(
        PeerAddr => $hostname,
        PeerPort => $port,
        Protp    => 'tcp',
        Timeout  => 10,
    ) || croak 'Cannot Connect';

    my $buff;
    $sock->recv($buff, BUFF_SIZE);
    $sock->send("list\n");
    $sock->recv($buff, BUFF_SIZE);
    my $avail_services = [ split(' ', $buff) ];

# sendしたコマンドに対する応答をなぜか得られないため，
# (前回のsendコマンドに対する応答を取得してしまったりする)
# 一旦すべてのserviceに対する応答をテキストとして取得する
    my @buff = map {
        my $buff;
        $sock->send("fetch $_\n");
        $sock->recv($buff, BUFF_SIZE);
        $buff;
    } @$avail_services;
    my $buffer = join("", @buff);

    $sock->send("quit\n");
    $sock->close;

    return hashify_response($avail_services, $buffer);
}


sub hashify_response {
    my ($avail_services, $buffer) = @_;

    my $i = 0;
    my $service_to_stat_to_value = {};
    my $lines = [ split('\n', $buffer) ];
    for my $line (@$lines) {
        if ($line eq '.') {
            $i++;
            next;
        };
        my $serv = $avail_services->[$i];
        my ($stat, $value) = split(' ', $line);
        next if !$stat or $stat eq '#';
        $stat =~ s/\./_/g;
        $service_to_stat_to_value->{$serv}->{$stat} = $value;
    }

    return $service_to_stat_to_value;
}

1;
__END__
