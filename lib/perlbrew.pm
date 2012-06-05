package perlbrew;

use strict;

use Rex -base;
use Rex::Commands::Run;

# Other modules:

# Module implementation
#

desc
    'install perlbrew (--install-root=[full-path-of-remote-folder] optional,  --system=1) ';
task 'install' => sub {
    my ($param) = @_;
    my $prepend
        = $param->{'install-root'}
        ? "export PERLBREW_ROOT=$param->{'install-root'}"
        : '';

    if ( can_run 'curl' ) {
        say run (
            $prepend
            ? "$prepend && curl -kL http://install.perlbrew.pl | bash"
            : "curl -kL http://install.perlbrew.pl | bash"
        );
    }
    elsif ( can_run 'wget' ) {
        say run (
            $prepend
            ? "$prepend &&  wget --no-check-certificate -O - http://install.perlbrew.pl | bash"
            : "wget-- no -check-certificate -O - http://install.perlbrew.pl | bash"
        );
    }
    else {
        die
            "need to install either of**curl* or ** wget**in remote machine\n";
    }

    # source perlbrew
    my $root = $param->{'install-root'} || '~/perl5/perlbrew';

    if ( exists $param->{system} ) {
        sudo "echo export PERLBREW_ROOT=$root >> /etc/profile.d/perlbrew.sh";
        sudo
            'echo source ${PERLBREW_ROOT}/etc/bashrc >> ~/etc/profile.d/perlbrew.sh';
    }
    else {
        run "echo export PERLBREW_ROOT=$root >> ~/.bashrc";
        run 'echo source ${PERLBREW_ROOT}/etc/bashrc >> ~/.bashrc';
    }

    # source in current shell
    run 'source /etc/profile && source ~/.bash_profile';
    needs perlbrew 'check';
    print "perlbrew is installed\n";
};

desc 'check if perlbrew is installed';
task 'check' => sub {
    if ( run 'echo ${PERLBREW_ROOT}' ) {
    }
    else {
        warn "perlbrew is not installed or not being set properly\n";
        die "install perlbrew using the install-perlbrew task\n";
    }
};

desc 'upgrade perlbrew';
task 'upgrade' => sub {
    needs perlbrew 'check';
    say run '$PERLBREW_ROOT/bin/perlbrew self-upgrade';
};

desc 'list available perl';
task 'list' => sub {
    needs perlbrew 'check';
    say run '$PERLBREW_ROOT/bin/perlbrew list';
};

desc 'list of installable perl';
task 'available' => sub {
    needs perlbrew 'check';
    say run '$PERLBREW_ROOT/bin/perlbrew available';
};

desc 'make this the default perl';
task 'switch' => sub {
    needs perlbrew 'check';

    my ($param) = @_;
    my $version = $param->{'perl-version'}
        or die "pass a version argument with --perl-version=\n";
    say run "\$PERLBREW_ROOT/bin/perlbrew switch $version";
};

1;    # Magic true value required at end of module

