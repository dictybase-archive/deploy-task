package  install;
use strict;
use Rex -base;
use Rex::Commands::Run;
use Rex::Commands::Gather;
use Rex::Commands::Pkg;

desc
    'install system packages needed for deployment of dictybase web applications';
task 'dicty-pack' => sub {
    update_package_db;
    install package => [
        qw/gcc curl wget make man gd gd-devel db4 db4-devel git vim-enhanced httpd
            mod_fastcgi mod_perl htop acl upstart daemontools bc/
    ];
};

1;    # Magic true value required at end of module

