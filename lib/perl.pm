package perl;

use strict;
use Rex -base;
use Rex::Commands::Run;
use Rex::Commands::Tail;

# Other modules:

# Module implementation
#

desc 'install perl using perlbrew';
task 'install' => sub {
        my ($param) = @_;
        needs perlbrew 'check';

        # start perl install and put it in the background
        my $version = $param->{version} || 'perl-5.10.1';
        run "nohup \$PERLBREW_ROOT/bin/perlbrew install $version </dev/null >perlbrew.log 2>&1 &";
 };

desc 'install threaded perl using perlbrew';
task 'install-threaded' => sub {
        my ($param) = @_;
        needs perlbrew 'check';

        # start perl install and put it in the background
        my $version = $param->{version} || 'perl-5.10.1';
        run "nohup \$PERLBREW_ROOT/bin/perlbrew install $version -Dusethread </dev/null >perlbrew.log 2>&1 &";
 };


desc 'get running status of perl installation process';
task 'install-status' => sub {
    needs perlbrew 'check';
	my $path = run 'echo $PERLBREW_ROOT';
	tail "$path/build.log";	   
};

1;    # Magic true value required at end of module
