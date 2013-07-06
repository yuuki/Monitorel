use t::monitoreltest;

use Test::mysqld;

use Cwd qw(getcwd);
use DBI;
use Qudo;
use Qudo::Test;

use Monitorel::Config;
use Monitorel::Worker::Qudo;
use Monitorel::Worker::Store::RRD::Path;


my $mysqld = Test::mysqld->new(
    my_cnf => {
        'skip-networking' => '', # no TCP socket
    }
) or plan skip_all => $Test::mysqld::errstr;

my $dbname = Monitorel::Config->param('TheSchwartz')->{dbname};
my $user   = Monitorel::Config->param('TheSchwartz')->{user};
my $passwd = Monitorel::Config->param('TheSchwartz')->{passwd};

my $dsn = $mysqld->dsn(dbname => '');
my $dbh = DBI->connect($dsn, 'root', '');
$dbh->do("CREATE DATABASE $dbname");
$dbh->do("use $dbname");

my $schema = Qudo::Test::load_schema;
for my $sql (@{$schema->{mysql}}) {
    $dbh->do($sql);
}

my $rrd_dir = Monitorel::Config->param('rrd_dir');

subtest 'qudo' => sub {
    my $client = Qudo->new(
        databases => [
            { dsn => $mysqld->dsn(dbname => $dbname), username => $user, password => $passwd }
        ],
        default_hooks => [qw(Qudo::Hook::Serialize::JSON)],
    );

    $client->enqueue('Monitorel::Worker::Qudo', {
        arg => {
            agent => 'Test',
            fqdn  => 'localhost',
            tag   => 'test',
            stats => [qw(response_num total_time)],
        }
    });

    my $worker = Qudo->new(
        databases => [
            { dsn => $mysqld->dsn(dbname => $dbname), user => 'root', passwd => ''}
        ],
        default_hooks => [qw(Qudo::Hook::Serialize::JSON)],
        manager_abilities => [qw(Monitorel::Worker::Qudo)],
    );
    $worker->manager->work_once;

    ok -f "$rrd_dir/localhost/test___response_num.rrd";
    ok -f "$rrd_dir/localhost/test___total_time.rrd";

    `rm -fr $rrd_dir/localhost`;
};
