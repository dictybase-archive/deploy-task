package  add;
use strict;
use Rex -base;
use Rex::Commands::Run;
use Rex::Commands::Gather;
use Rex::Commands::File;
use Rex::Commands::Fs;
use File::Basename;
use Try::Tiny;

my $resp_callback = sub {
    my ( $stdout, $stderr ) = @_;
    my $server = Rex::get_current_connection()->{server};
    say "[$server: ] $stdout\n" if $stdout;
    say "[$server: ] $stderr\n" if $stderr;
};

desc
    'add ELRepo repository for RHEL 6.0 or any of its derivative(CentOs etc...) system';
task 'elrepo' => sub {

    # -- guess the os for command
    if ( !is_redhat ) {
        die "your Os is not supported\n";
    }
    run 'rpm --import http://elrepo.org/RPM-GPG-KEY-elrepo.org',
        $resp_callback;
    run 'rpm -Uvh http://elrepo.org/elrepo-release-6-4.el6.elrepo.noarch.rpm',
        $resp_callback;
};

desc 'add a new sudoers file(--file=filepath) in /etc/sudoers.d';
task 'sudoers' => sub {
    my ($param) = @_;
    die "pass a file name using (--file) argument\n"
        if not exists $param->{file};
    die "given file $param->{file} do not exist\n" if !-e $param->{file};

    my $name = basename $param->{file};
    if ( is_dir('/etc/sudoers.d') ) {
        try {
            my $fh = file_write("/etc/sudoers.d/$name");
            my $text = do { local ( @ARGV, $/ ) = $param->{file}; <> };
            $fh->write($text);
            $fh->close;
        }
        catch {
            die "error in writing:$_\n";
        };
    }
    else {
        warn "/etc/sudoers.d folder do not exist in remote server!!!\n";
    }
};

desc 'add new groups(--name=group1:group2:...) [only in remote linux system]';
task 'groups' => sub {
    my ($param) = @_;
    die "no group name is given,  pass group using (--name=) argument\n"
        if not exists $param->{name};

    if (!can_run('groupadd')) {
    	die "remote system do not support *groupadd* command\n";
    }
    
    if ( $param->{name} =~ /:/ ) {
        for my $g ( split /:/, $param->{name} ) {
            run "groupadd $g" ;
        }
    }
    else {
    	run "groupadd $param->{name}";
    }
};

1;    # Magic true value required at end of module

