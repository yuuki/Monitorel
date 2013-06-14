package Monitorel::Worker::Agent::Munin;
use strict;
use warnings;
use utf8;
use parent qw(Monitorel::Worker);

use Carp qw(croak);
use IO::Socket;
use constant BUFF_SIZE => 20000;

our $DEFAULT_PORT = 4949;

sub proc {
    my ($class, $args) = @_;

    my $hostname = $args->{host}  // croak "host key must not be empty";
    my $services = $args->{stats};
    my $port     = $args->{port}  || $DEFAULT_PORT;

    _munin_service_to_stat_to_value($hostname, $port);
}

sub _munin_service_to_stat_to_value {
    my ($hostname, $port) = @_;

    my $sock = IO::Socket::INET->new(
        PeerAddr => $hostname,
        PeerPort => $port,
        Protp    => 'tcp',
        Timeout  => 10,
    ) || croak 'Cannot Connect';

    my $avail_services = _avail_services($sock);
    my $buffer = _munin_response($sock, $avail_services);

    $sock->send("quit\n");
    $sock->close;

    _hashify_response($avail_services, $buffer);
}

sub _avail_services {
    my $sock = shift;

    my $buff;
    $sock->recv($buff, BUFF_SIZE);
    $sock->send("list\n");
    $sock->recv($buff, BUFF_SIZE);
    [ split(' ', $buff) ];
}

# sendしたコマンドに対する応答をなぜか得られないため，
# (前回のsendコマンドに対する応答を取得してしまったりする)
# 一旦すべてのserviceに対する応答をテキストとして取得する
sub _munin_response {
    my ($sock, $services) = @_;

    my @buff = map {
        my $buff;
        $sock->send("fetch $_\n");
        $sock->recv($buff, BUFF_SIZE);
        $buff;
    } @$services;
    join("", @buff);
}

sub _hashify_response {
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

    $service_to_stat_to_value;
}

1;
__END__
