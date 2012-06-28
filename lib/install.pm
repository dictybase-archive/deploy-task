package  install;
use strict;
use Rex -base;
use Rex::Commands::Run;
use Rex::Commands::Gather;
use Rex::Commands::Pkg;

desc
    'install system packages needed for deployment of dictybase web applications';
task 'dicty-pack' => sub {
    run 'yum -y install gcc curl wget make man gd gd-devel db4 db4-devel git \
        vim-enhanced httpd mod_fastcgi mod_perl htop acl upstart daemontools bc \
        libxml2-devel expat-devel acl';
};

desc 'install system perl';
task 'perl' => sub {
    run 'which perl';
    if ( $? != 0 ) {
        run 'yum -y install perl';
    }
    else {
        warn "system perl is installed\n";
    }
};

1;    # Magic true value required at end of module

