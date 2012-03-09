package  install;
use strict;
use Rex -base;
use Rex::Commands::Run; 
use Rex::Commands::Gather;

desc 'install a package (only redhat and ubuntu supported) with sudo access';
task 'package' => sub {
	my ($param) = @_;
	die "no package name given\n" if not defiend $param->{package};
	$package = $param->{package};

	my $cmd;
	# -- guess the os for command
	if (is_redhat) {
		$cmd = "sudo yum -y install $package";
	}
	elsif (is_debian) {
		$cmd = "sudo apt-get -y install $package";
	}
	else {
		die "your Os is not supported\n";
	}
	run $cmd;
};




1;    # Magic true value required at end of module

