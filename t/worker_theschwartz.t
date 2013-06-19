use t::monitoreltest;

use Test::mysqld;

use Cwd qw(getcwd);
use DBI;
use TheSchwartz;

use Monitorel::Config;
use Monitorel::Worker::TheSchwartz;
use Monitorel::Worker::Store::RRD::Path;


my $mysqld = Test::mysqld->new(
    my_cnf => {
        'skip-networking' => '', # no TCP socket
    }
) or plan skip_all => $Test::mysqld::errstr;

open my $fh, "< db/schema_theschwartz.sql";
my $schema = do { local $/ = undef; <$fh> };
close $fh;

my $dbname = Monitorel::Config->param('TheSchwartz')->{dbname};
my $user   = Monitorel::Config->param('TheSchwartz')->{user};
my $passwd = Monitorel::Config->param('TheSchwartz')->{passwd};

my $dsn = $mysqld->dsn(dbname => '');
my $dbh = DBI->connect($dsn, 'root', '');
$dbh->do("CREATE DATABASE $dbname");
$dbh->do("use $dbname");
$dbh->do($_) for split /;\s*/, $schema;

subtest 'theschwartz' => sub {
    my $client = TheSchwartz->new(
        databases => [{
            dsn => $mysqld->dsn(dbname => $dbname), user => $user, passwd => $passwd
        }],
    );

    my $rrd_dir = Monitorel::Config->param('rrd_dir');
    Monitorel::Worker::Store::RRD::Path->set_rrddir($rrd_dir);

    my $job_id = $client->insert('Monitorel::Worker::TheSchwartz', {
        agent => 'Test',
        fqdn  => 'localhost',
        tag   => 'test',
        stats => [qw(response_num total_time)],
    });

    $client->can_do('Monitorel::Worker::TheSchwartz');
    $client->work_once;

    ok -f "$rrd_dir/localhost/test___response_num.rrd";
    ok -f "$rrd_dir/localhost/test___total_time.rrd";

    `rm -fr $rrd_dir/localhost`;
};
