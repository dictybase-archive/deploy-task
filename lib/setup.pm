package  setup;
use strict;
use Rex -base;
use Rex::Commands::Run; 


desc 'Install and setup daemontools(v 0.76) from source (done as sudo)';
task 'daemontools',  sub {
	my $dirname = 'daemontools-0.76';
	run 'sudo mkdir -p /package && sudo chmod 1755 /package';
	run 'cd /package && sudo curl -O http://cr.yp.to/daemontools/daemontools-0.76.tar.gz';
	run 'cd /package && sudo tar xvzf daemontools-0.76.tar.gz';

	# patch for installing in linux
	run "cd /package/admin/$dirname && sudo sed -i 's/^\\(gcc.*\\)\$/\\1 \-include \\/usr\\/include\\/errno\\.h/' ./src/conf-cc";

	# compile daemontools and then create /service and /command
	run "cd /package/admin/$dirname && sudo ./package/install";

	# now the post install task
	# fixing the startup particurarly for ubuntu and redhat which uses upstart

	#1. Remove the line added in /etc/inittab
	run "sudo sed -i '/^SV/d' /etc/inittab";

	#2. Generate startup file for upstart
	run "echo -e 'start on runlevel [12345]\nrespawn\nexec /command/svscanboot' | sudo tee /etc/init/svscan.conf";
	run 'sudo initctl reload-configuration && sudo initctl start svscan';
};


1;    # Magic true value required at end of module

