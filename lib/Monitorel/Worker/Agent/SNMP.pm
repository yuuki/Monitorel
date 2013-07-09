package Monitorel::Worker::Agent::SNMP;
use strict;
use warnings;

use Carp qw(croak);
use Net::SNMP;

sub proc {
    my ($class, $args) = @_;

    my $hostname  = $args->{host}  or croak "host requried";
    my $oids      = $args->{stats} or croak "stats requried";
    my $community = $args->{community} || 'public';

    my ($session, $error) = Net::SNMP->session(
        -hostname  => $hostname,
        -community => $community,
        -version   => 2,
        -timeout   => 10,
        -translate => 0x0,  # sysUpTime becomes not human readble string but numeric value
    );
    $session or croak "SNMP error: $error";

    my $response = $session->get_request(
        -varbindlist => $oids,
    ) or croak "SNMP error: $session->error";

    $session->close;

    return $response;
}

1;
__END__
