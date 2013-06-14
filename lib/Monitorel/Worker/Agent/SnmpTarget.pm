package Monitorel::Worker::Agent::SnmpTarget;
use strict;
use warnings;
use parent qw(Monitorel::Worker);

use Carp qw(croak);
use Clone qw(clone);
use Net::SNMP;
use File::Which qw(which);


sub proc {
    my ($class, $args) = @_;

    my $hostname    = $args->{host}  // croak "host key must not be empty";
    my $oids        = $args->{stats} // croak "stats key must not be empty";
    my $community   = $args->{community} || 'public';

    _snmp_response($hostname, $community, $oids);
}

sub _snmp_response {
    my ($hostname, $community, $mibs) = @_;

    my ($session, $error) = Net::SNMP->session(
        -hostname  => $hostname,
        -community => $community,
        -version   => 2,
        -timeout   => 10,
        -translate => 0x0,  # sysUpTime becomes not human readble string but numeric value
    );
    $session // croak "SNMP error: $error";

    my $response = $session->get_request(
        -varbindlist => $mibs,
    ) || croak "SNMP error: $session->error";

    $session->close;

    $response;
}

1;
__END__
