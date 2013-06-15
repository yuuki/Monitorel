use utf8;
use strict;
use warnings;
use lib lib => 't/lib';

use Test::More skip_all => "ops";
use Test::mysqld;

use DBI;
use TheSchwartz::Simple;
use Path::Class;

use Monitorel::Worker::Agent::Schwartz;

my $mysqld = Test::mysqld->new(
    my_cnf => {
        'skip-networking' => '', # no TCP socket
    }
) or plan skip_all => $Test::mysqld::errstr;

open my $fh, "< db/schema_theschwartz.sql";
my $schema = do { local $/ = undef; <$fh> };
close $fh;

my $dsn = $mysqld->dsn(dbname => '');
my $dbname = 'test_theschwartz_worker';
my $dbh = DBI->connect($dsn, 'root', '');
$dbh->do("CREATE DATABASE $dbname");
$dbh->do("use $dbname");
$dbh->do($_) for split /;\s*/, $schema;

$dsn = $mysqld->dsn(dbname => $dbname);

subtest proc => sub {
    my $stats = ["Worker1", "Worker2", "Worker3"];

    {
        my $client = TheSchwartz::Simple->new([$dsn]);
        $client->insert($stats->[0], 10);
        $client->insert($stats->[0], 11);
        $client->insert($stats->[0], 12);
        $client->insert($stats->[1], 13);
        $client->insert($stats->[2], 14);
    }

    my $result = Monitorel::Worker::Agent::Schwartz->proc({
        dsn      => $dsn,
        dbuser   => 'root',
        dbpass   => '',
    });

    is $result->{$stats->[0]}, 3;
    is $result->{$stats->[1]}, 1;
    is $result->{$stats->[2]}, 1;

};

my $tables = $dbh->table_info('', '', '%', 'TABLE')->fetchall_arrayref({});
$dbh->do("TRUNCATE `$_`") for map { $_->{TABLE_NAME} } @$tables;
$dbh->disconnect;

done_testing;
