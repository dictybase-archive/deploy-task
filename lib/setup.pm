package  setup;
use strict;
use Rex -base;
use Rex::Commands::Run; 
use Rex::Commands::Fs;


desc 'Install and setup daemontools(v 0.76) from source';
task 'daemontools',  sub {
	my $dirname = 'daemontools-0.76';
	run 'mkdir -p /package && chmod 1755 /package';
	run 'cd /package &&  curl -O http://cr.yp.to/daemontools/daemontools-0.76.tar.gz';
	run 'cd /package &&  tar xvzf daemontools-0.76.tar.gz';

	# patch for installing in linux
	run "cd /package/admin/$dirname &&  sed -i 's/^\\(gcc.*\\)\$/\\1 \-include \\/usr\\/include\\/errno\\.h/' ./src/conf-cc";

	# compile daemontools and then create /service and /command
	run "cd /package/admin/$dirname &&  ./package/install";

	# now the post install task
	# fixing the startup particurarly for ubuntu and redhat which uses upstart

	#1. Remove the line added in /etc/inittab
	run " sed -i '/^SV/d' /etc/inittab";

	#2. Generate startup file for upstart
	run "echo -e 'start on runlevel [12345]\nrespawn\nexec /command/svscanboot' |  tee /etc/init/svscan.conf";
	run ' initctl reload-configuration &&  initctl start svscan';
};

desc 'setup shared folder (--group=deploy and --folder=/dictybase options) for deployment and common web developmental tasks';
task 'shared-folder' => sub {
	my ($param) = @_;

	my $group = $param->{group} || 'deploy';
	my $folder = $param->{folder} || '/dictybase';
	warn "the shared folder $folder has to be remounted with *acl* support\n";

	chgrp $group, $folder;
	run "chmod g+r,g+w,g+x,g+s $folder";
	run "setfacl -k -b $folder && setfacl -d -m u::rwx,g::rwx,o::r-- $folder";
};


1;    # Magic true value required at end of module

