package  add;
use strict;
use Rex -base;
use Rex::Commands::Run; 
use Rex::Commands::Gather;

my $resp_callback = sub {
	my ($stdout, $stderr) = @_;
	my $server = Rex::get_current_connection()->{server};
	say "[$server: ] $stdout\n" if $stdout;
	say "[$server: ] $stderr\n" if $stderr;
};

desc 'add ELRepo repository for RHEL 6.0 or any of its derivative(CentOs etc...) system';
task 'elrepo' => sub {
	# -- guess the os for command
	if (!is_redhat) {
		die "your Os is not supported\n";
	}
	sudo sub { 
	   run 'rpm --import http://elrepo.org/RPM-GPG-KEY-elrepo.org',  $resp_callback;
	   run 'rpm -Uvh http://elrepo.org/elrepo-release-6-4.el6.elrepo.noarch.rpm' , $resp_callback;
	};
};

1;    # Magic true value required at end of module

