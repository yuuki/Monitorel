use utf8;
use strict;
use warnings;
use lib 'lib' => 't/lib';

use Test::More;
use Test::mysqld;

use Cwd qw(getcwd);
use DBI;
use TheSchwartz;
use RRDTool::Rawish;

use Monitorel::Worker::Store::RRD::Path;


my $mysqld = Test::mysqld->new(
    my_cnf => {
        'skip-networking' => '', # no TCP socket
    }
) or plan skip_all => $Test::mysqld::errstr;


open my $fh, "< db/schema_theschwartz.sql";
my $schema = do { local $/ = undef; <$fh> };
close $fh;

my $dsn = $mysqld->dsn(dbname => '');
my $dbname = 'test_theschwartz';
my $dbh = DBI->connect($dsn, 'root', '');
$dbh->do("CREATE DATABASE $dbname");
$dbh->do("use $dbname");
$dbh->do($_) for split /;\s*/, $schema;

subtest 'worker normal test' => sub {
    my $client = TheSchwartz->new(
        databases => [{ dsn => $mysqld->dsn(dbname => $dbname), user => 'root', passwd => ''} ],
        verbose   => 1,
    );

    my $rrd_dir = getcwd . '/tmp';
    Monitorel::Worker::Store::RRD::Path->set_rrddir($rrd_dir);

    my $job_id = $client->insert('Worker::Test', {
        fqdn  => 'localhost',
        tag   => 'test',
        stats => [qw(response_num total_time)],
    });

    $client->can_do('Worker::Test');
    $client->work_once;

    ok -f "$rrd_dir/localhost/test___response_num.rrd";
    ok -f "$rrd_dir/localhost/test___total_time.rrd";

    `rm -fr $rrd_dir/localhost`;
};

done_testing;


##################################################
package Worker::Test;
use strict;
use warnings;

use parent qw(Monitorel::Worker);

sub proc {
    my ($class, $args) = @_;
    return +{
        response_num => 1000,
        total_time   => 12345678,
    };
}

