use t::monitoreltest;

use Test::Mock::Guard qw(mock_guard);

use Monitorel::Worker::Agent::Munin;

subtest proc => sub {

    my $mock = mock_guard 'IO::Socket::INET',
    +{
        new => sub { bless { command => undef }, shift; },
        send => sub {
            my ($self, $command) = @_;
            $self->{command} = $command;
        },
        recv => sub {
            my $self = shift;
            return unless defined $self->{command};

            if ($self->{command} =~ /^list/) {
                $_[0] = "cpu memory\n";
            }
            elsif ($self->{command} =~ /^fetch cpu/) {
                $_[0] = <<'EOS';
user.value 2565520
nice.value 8799098
system.value 4536548
idle.value 11060842647
iowait.value 653458
irq.value 0
softirq.value 5501
steal.value 334539
.
EOS
            }
            elsif ($self->{command} =~ /^fetch memory/) {
                $_[0] = <<'EOS';
slab.value 133419008
swap_cache.value 0
page_tables.value 6172672
vmalloc_used.value 1429504
apps.value 377643008
free.value 443801600
buffers.value 349769728
cached.value 836677632
swap.value 135168
committed.value 2371792896
mapped.value 16035840
active.value 869703680
inactive.value 618102784
.
EOS
            }
        },
        close => sub {},
    };

    my $result = Monitorel::Worker::Agent::Munin->proc(+{
        host  => 'localhost',
        stats => [qw(cpu memory)],
        port  => 4949,
    });

    ok $result;
    is $result->{cpu}->{user_value}, 2565520;
    is $result->{cpu}->{nice_value}, 8799098;
    is $result->{cpu}->{system_value}, 4536548;
    is $result->{cpu}->{idle_value}, 11060842647;
    is $result->{cpu}->{iowait_value}, 653458;
    is $result->{cpu}->{irq_value}, 0;
    is $result->{cpu}->{softirq_value}, 5501;
    is $result->{cpu}->{steal_value}, 334539;

    is $result->{memory}->{slab_value}, 133419008;
    is $result->{memory}->{swap_cache_value}, 0;
    is $result->{memory}->{page_tables_value}, 6172672;
    is $result->{memory}->{vmalloc_used_value}, 1429504;
    is $result->{memory}->{apps_value}, 377643008;
    is $result->{memory}->{free_value}, 443801600;
    is $result->{memory}->{buffers_value}, 349769728;
    is $result->{memory}->{cached_value}, 836677632;
    is $result->{memory}->{swap_value}, 135168;
    is $result->{memory}->{committed_value}, 2371792896;
    is $result->{memory}->{mapped_value}, 16035840;
    is $result->{memory}->{active_value}, 869703680;
    is $result->{memory}->{inactive_value}, 618102784;
};
