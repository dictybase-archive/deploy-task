package  setup::dicty;
use strict;
use Rex -base;
use Rex::Commands::Run;
use Rex::Commands::Fs;
use Rex::Commands::File;
use Rex::Config;
use Rex::TaskList;
use Rex::Interface::Exec::Sudo;

desc 'install and setup perl environment for dictybase deployment';
task 'perl' => sub {
    Rex::Config->register_config_handler(
        perlbrew => sub {
            my ($param) = @_;
            Rex::TaskList->run(
                'perlbrew:install',
                params => {
                    'install-root' => $param->{root},
                    'system'       => 1
                }
            );

            do_task 'perlbrew:lib:install-cpanm';

            Rex::TaskList->run( 'perl:install-notest',
                params => { version => $param->{perl} } );
        }
    );

};

desc 'setup default perl and install toolchain for dictybase development';
task 'perl-toolchain' => sub {
    Rex::Config->register_config_handler(
        perlbrew => sub {
            my ($param) = @_;    	
            Rex::TaskList->run( 'perlbrew:switch',
                params => { version => $param->{perl} } );
            do_task 'perl:install-toolchain';
        }
    );
};

desc
    'set up a remote box for dictybase deployment by running a bunch of tasks';
task 'box' => sub {

    Rex::Config->register_config_handler(
        sudo => sub {
            my ($param) = @_;
            Rex::TaskList->run( 'add:sudoers',
                params => { file => $param->{file} } );
        }
    );

    do_task 'add:repos';
    do_task 'install:dicty-pack';
    do_task 'setup:daemontools';

    Rex::Config->register_config_handler(
        group => sub {
            my ($param) = @_;
            Rex::TaskList->run( 'add:groups',
                params => { name => $param->{name} } );
        }
    );
    Rex::Config->register_config_handler(
        user => sub {
            my ($param) = @_;
            Rex::TaskList->run( 'add:user',
                params => { map { $_ => $param->{$_} } qw/user pass groups/ }
            );
        }
    );

    Rex::Config->register_config_handler(
        shared => sub {
            my ($param) = @_;
            Rex::TaskList->run( 'setup:shared-folder',
                params =>
                    { map { $_ => $param->{$_} } qw/group folder device/ } );
        }
    );
    Rex::Config->register_config_handler(
        oracle => sub {
            my ($param) = @_;
            Rex::TaskList->run( 'setup:oracle-client',
                params => { rpm => $param->{rpm} } );
            Rex::TaskList->run( 'setup:oracle:tnsnames',
                params =>
                    { map { $_ => $param->{$_} } qw/file host sid service/ }
            );
        }
    );
    Rex::Config->register_config_handler(
        mojo => sub {
            my ($param) = @_;
            Rex::TaskList->run( 'setup:global-mojo',
                params => { mode => $param->{mode} } );
        }
    );
    Rex::Config->register_config_handler(
        apache => sub {
            my ($param) = @_;
            Rex::TaskList->run( 'setup:apache:envvars',
                params => { file => $param->{envvars}->{file} } );
            Rex::TaskList->run(
                'setup:apache:vhost',
                params => {
                    file => $param->{vhost}->{file},
                    name => $param->{vhost}->{name}
                }
            );
            Rex::TaskList->run( 'setup:apache:perl-code',
                params => { file => $param->{perl}->{file} } );
        }
    );
    do_task 'setup:apache:fastcgi-fix';
    do_task 'setup:apache:startup';
};

1;    # Magic true value required at end of module

