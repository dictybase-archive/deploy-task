package  setup;
use strict;
use Rex -base;
use Rex::Commands::Run;
use Rex::Commands::Fs;
use Rex::Commands::Upload;
use Rex::Commands::File;

desc 'Add daemontools to run via upstart';
task 'daemontools', sub {

    #Generate startup file for upstart
    my $fh = file_write('/etc/init/svscan.conf');
    $fh->write("start on runlevel [12345]\nrespawn\n");
    $fh->write("exec /command/svscanboot");
    $fh->close;
    run 'initctl reload-configuration &&  initctl start svscan';
};

desc
    'setup shared folder (--group=deploy and --folder=/dictybase options) for deployment and common web developmental tasks';
task 'shared-folder' => sub {
    my ($param) = @_;

    my $group  = $param->{group}  || 'deploy';
    my $folder = $param->{folder} || '/dictybase';
    warn "the shared folder $folder has to be remounted with *acl* support\n";

    chgrp $group, $folder;
    run "chmod g+r,g+w,g+x,g+s $folder";
    run "setfacl -k -b $folder && setfacl -d -m u::rwx,g::rwx,o::r-- $folder";

    if ( is_dir('/service') ) {    #it should be writable by deploy group
        chgrp $group, '/service';
        chmod 'g+w', '/service';
    }
};

desc
    'install(--rpm=<folder>) and setup environment for oracle instantclient for Redhat Os';
task 'oracle-client' => sub {
    my ($param) = @_;
    die "no rpm folder(--rpm=<folder>) given\n" if not exists $param->{rpm};

    my @rpms;
    LOCAL {
        @rpms = glob("$param->{rpm}/oracle-instantclient-*.rpm");
        die
            "did not get any oracle instantclient rpm(s) from $param->{rpm} !!!!\n"
            if scalar @rpms == 0;
    };

    # upload the rpms
    my $tmpdir = run 'mktemp -d';
    upload $_, $tmpdir for @rpms;

    # install
    sudo "rpm -i $tmpdir/*basic*.rpm && rpm -i $tmpdir/*sqlplus*.rpm";

    #extract value of lib folder
    my $lib = run "dirname `(rpm -qlp $tmpdir/*basic*.rpm | grep libclntsh)`";
    my $bin = run
        "dirname `(rpm -qlp $tmpdir/*sqlplus*.rpm | grep -E 'sqlplus\$')`";

    sudo "echo export ORACLE_HOME=$lib >> /etc/profile.d/oracle.sh";
    sudo "echo \' export PATH=\$PATH:$bin \' >> /etc/profile.d/oracle.sh";
    sudo "echo $lib >> /etc/ld.so.conf.d/oracle.conf";
};

desc
    'setup global env vars(--mode=[production] --log-level=[error]) for mojolicious web application deployment';
task 'global-mojo' => sub {
    my ($param) = @_;
    my $mode      = $param->{mode}        || 'production';
    my $log_level = $param->{'log-level'} || 'error';

    run "echo export MOJO_MODE=$mode >> /etc/profile.d/mojolicious.sh";
    run
        "echo export MOJO_LOG_LEVEL=$log_level >> /etc/profile.d/mojolicious.sh";
};

1;    # Magic true value required at end of module

