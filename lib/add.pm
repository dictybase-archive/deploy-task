package  add;
use strict;
use Rex -base;
use Rex::Commands::Run;
use Rex::Commands::Gather;
use Rex::Commands::File;
use Rex::Commands::Fs;
use Rex::Commands::User;
use File::Basename;
use Try::Tiny;

my $resp_callback = sub {
    my ( $stdout, $stderr ) = @_;
    my $server = Rex::get_current_connection()->{server};
    say "[$server: ] $stdout\n" if $stdout;
    say "[$server: ] $stderr\n" if $stderr;
};

sub _check_user {
    my ($user) = @_;
    run "id -u $user";
    if ( $? == 0 ) {
        return $user;
    }
}

desc 'add extra 3rd party repositories(elrepo,rpmforge and atomicorp)';
task 'repos' => sub {
    needs add qw/elrepo rpmforge atomicorp/;
};

desc
    'add ELRepo repository for RHEL 6.0 or any of its derivative(CentOs etc...) system';
task 'elrepo' => sub {

    # -- guess the os for command
    run 'rpm --import http://elrepo.org/RPM-GPG-KEY-elrepo.org',
        $resp_callback;
    run 'rpm -Uvh http://elrepo.org/elrepo-release-6-4.el6.elrepo.noarch.rpm',
        $resp_callback;
};

desc
    'add rpmforge repository for RHEL 6.0 or any of its derivative(CentOs etc...) system';
task 'rpmforge' => sub {
    run 'rpm --import http://apt.sw.be/RPM-GPG-KEY.dag.txt', $resp_callback;
    run
        'rpm -Uvh http://packages.sw.be/rpmforge-release/rpmforge-release-0.5.2-2.el6.rf.x86_64.rpm',
        $resp_callback;
};

desc
    'add atomicorp repository for RHEL 6.0 or any of its derivaties(CentOs etc ...) system';
task 'atomicorp' => sub {
    run
        'rpm -Uvh http://www6.atomicorp.com/channels/atomic/centos/6/i386/RPMS/atomic-release-1.0-14.el6.art.noarch.rpm',
        $resp_callback;
};

desc 'add a new sudoers file(--file=filepath) in /etc/sudoers.d';
task 'sudoers' => sub {
    my ($param) = @_;
    die "pass a file name using (--file) argument\n"
        if not exists $param->{file};
    die "given file $param->{file} do not exist\n" if !-e $param->{file};

    if ( is_dir('/etc/sudoers.d') ) {
        my $name = basename $param->{file};
        my $fh   = file_write("/etc/sudoers.d/$name");
        my $text = do { local ( @ARGV, $/ ) = $param->{file}; <> };
        $fh->write($text);
        $fh->close;
    }
    else {
        warn "/etc/sudoers.d do not exist\n";
        warn "or disable requirestty option in /etc/sudoers\n";
    }
};

desc 'add new groups(--name=group1:group2:...) [only in remote linux system]';
task 'groups' => sub {
    my ($param) = @_;
    die "no group name is given,  pass group using (--name=) argument\n"
        if not exists $param->{name};

    if ( !can_run('groupadd') ) {
        die "remote system do not support *groupadd* command\n";
    }

    if ( $param->{name} =~ /:/ ) {
        for my $g ( split /:/, $param->{name} ) {
            run "groupadd $g";
        }
    }
    else {
        run "groupadd $param->{name}";
    }
};

desc
    'add new(--user=username and --pass=passwd) user (pass --groups=group1:group2 to add it to groups)';
task 'user' => sub {
    my ($param) = @_;
    die "no user name(--user) is given\n" if not exists $param->{user};

    my $cmd = 'useradd -m';
    if ( _check_user( $param->{user} ) ) {
        $cmd = 'usermod -a ';
        warn "$param->{user} exists!!! going to add it to $param->{groups}\n";
    }
    else {
        die "no password(--pass) is given to create a new user\n"
            if not exists $param->{pass};
    }

    my $opt;
    $opt->{password} = $param->{pass};
    if ( defined $param->{groups} ) {
        if ( $param->{groups} =~ /:/ ) {
            for my $g ( split /:/, $param->{groups} ) {
                push @{ $opt->{groups} }, $g;
            }
        }
        else {
            push @{ $opt->{groups} }, $param->{groups};
        }
    }
    $cmd .= ' -G ' . join( ',', @{ $opt->{groups} } ) . ' ' . $param->{user};
    run $cmd;

    if ( $? != 0 ) {
        die "$param->{user} is not created!!!!!\n";
    }

    # now the password
    if ( $cmd =~ /useradd/ ) {
        my $passcmd = "echo $param->{pass}:$param->{user} | chpasswd";
        run $passcmd;
        if ( $? != 0 ) {
            die "could not create password for user!!!! \n";
        }
    }
};

1;    # Magic true value required at end of module

