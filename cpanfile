
requires 'Clone';
requires 'DBI', 1.627;
requires 'Exporter::Lite';
requires 'LWP::UserAgent', 6.05;
requires 'Net::SNMP', '6.0.1';
requires 'Net::Telnet';
requires 'Path::Class';
requires 'RRDTool::Rawish', 0.031;
requires 'Time::HiRes';
requires 'TheSchwartz', 1.10;

on test => sub {
    requires 'Test::More', 0.98;
    requires 'Test::Fatal';
    requires 'Test::Mock::Guard';
    requires 'Test::Mock::LWP::Conditional';
    requires 'Test::mysqld', 0.17;
    requires 'TheSchwartz::Simple';
};

on configure => sub {
};

on 'develop' => sub {
};
