use utf8;
use strict;
use warnings;
use lib lib => 't/lib';

use Test::More;
use Test::Mock::Guard qw(mock_guard);

use Monitorel::Worker::Agent::MySQLStat;


subtest proc => sub {
    my $st_mock = mock_guard 'DBI::st',
        +{
            new => sub {
                my ($class, $sql) = @_;
                bless {sql => $sql}, $class;
            },
            execute => sub {},
            fetchall_arrayref => sub {
                my $self = shift;
                if ($self->{sql} eq q|show /*!50002 global */ status|) {
                    [
                        ["Bytes_received", 1],
                        ["Bytes_sent", 2],
                        ["Com_insert", 3],
                        ["Com_select", 4],
                        ["Com_update", 5],
                        ["Com_update_multi", 6],
                    ];
                }
            },
            fetchrow_hashref => sub { {} },
            finish => sub {},
        };

    my $db_mock = mock_guard 'DBI::db',
        +{
            prepare => sub {
                my ($self, $sql) = @_;
                DBI::st->new($sql);
            },
        };

    my $mock = mock_guard 'DBI',
        +{
            connect => sub {
                "DBI::db";
            },
        };

    my $result = Monitorel::Worker::Agent::MySQLStat->proc(
        +{
            stats  => [ qw(Bytes_received Com_update) ],
            host   => 'localhost',
            dbuser => 'root',
            dbpass => '',
        },
    );

    is $result->{Bytes_received}, 1;
    is $result->{Com_update}, 5;
};

done_testing;
