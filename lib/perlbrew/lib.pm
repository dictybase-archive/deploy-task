package perlbrew::lib;

use strict;
# Other modules:
use Rex -base;
use Rex::Commands::Run;

# Module implementation
#

desc 'install cpanm for the current perlbrew';
task 'install-cpanm' => sub {
    	needs perlbrew 'check';
        run '$PERLBREW_ROOT/bin/perlbrew install-cpanm';
};

desc 'create new local lib(--local-lib) for the perl version(--perl-version)under perlbrew';
task 'create' => sub {
        needs perlbrew 'check';
        my ($param) = @_;
        my $lib = $param->{'local-lib'} || die "need local-lib option\n";
        my $cmd;
        if (my $version = $param->{'perl-version'}) {
        	$cmd = "\$PERLBREW_ROOT/bin/perlbrew lib create $version\@$lib";
        }
        else {
        	$cmd = "\$PERLBREW_ROOT/bin/perlbrew lib create $lib";	
        	
        }
        run $cmd;
};


1;    # Magic true value required at end of module

