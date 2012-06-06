package  install;
use strict;
use Rex -base;
use Rex::Commands::Run;
use Rex::Commands::Gather;
use Rex::Commands::Pkg;

#desc 'install a package(--package) (only redhat and ubuntu supported) with sudo access';
#task 'package' => sub {
#	my ($param) = @_;
#	die "no package name given\n" if not defiend $param->{package};
#	$package = $param->{package};
#
#	my $cmd;
#	 -- guess the os for command
#	if (is_redhat) {
#		$cmd = "sudo yum -y install $package";
#	}
#	elsif (is_debian) {
#		$cmd = "sudo apt-get -y install $package";
#	}
#	else {
#		die "your Os is not supported\n";
#	}
#	run $cmd;
#};
#
desc
    'install system packages needed for deployment of dictybase web applications';
task 'dicty-pack' => sub {
    update_package_db;
    install package => [
        qw/gcc curl wget make man gd db4 db4-devel git vim-enhanced httpd
            mod_fastcgi htop acl upstart gpgme/
    ];
};

1;    # Magic true value required at end of module

