use utf8;
use strict;
use warnings;
use lib lib => 't/lib';

use Test::More skip_all => "require Test::mysqld";
use DBI;
use TheSchwartz::Simple;
use Path::Class;

use Monitorel::Worker::Agent::Schwartz;



my ($host, $port) = ('localhost', 3306);
my $dbuser = config('db.mackerel')->{user};
my $dbpass = config('db.mackerel')->{passwd};
my $dbh = DBI->connect("DBI:mysql:theschwartz:$host:$port", $dbuser, $dbpass);


subtest proc => sub {
    my $stats = ["Hatena-Bookmark-Worker", "Hatena-Dirary-Worker", "Hatena-Ugomemo-Worker"];

    {
        my $client = TheSchwartz::Simple->new([$dbh]);
        $client->insert($stats->[0], 10);
        $client->insert($stats->[0], 11);
        $client->insert($stats->[0], 12);
        $client->insert($stats->[1], 13);
        $client->insert($stats->[2], 14);
    }

    my $result = Monitorel::Worker::Agent::Schwartz->proc({
        host     => $host,
        dbuser   => $dbuser,
        dbpass   => $dbpass,
        port     => $port,
    });

    is $result->{$stats->[0]}, 3;
    is $result->{$stats->[1]}, 1;
    is $result->{$stats->[2]}, 1;

    my $tables = $dbh->table_info('', '', '%', 'TABLE')->fetchall_arrayref({});
    $dbh->do("TRUNCATE `$_`") for map { $_->{TABLE_NAME} } @$tables;
    $dbh->disconnect;
};

done_testing;
