package git;

use strict;
use Rex -base;
use Rex::Commands::Run; 
use Rex::Commands::Gather;


desc 'Install git (requires sudo access) only for redhat based Os';
task 'install',  sub {
	if (is_redhat) {
		run 'sudo yum -y install git';
	}
	else {
		warn "remote server is not redhat based system:  git cannot be installed\n";
	}
};


1;    # Magic true value required at end of module

