package git::deploy;

use strict;
use Rex -base;
use Rex::Commands::Run;
use Rex::Commands::Fs;
use Rex::Commands::Gather;
use Rex::Commands::File;
use File::Spec::Functions qw/catfile curdir updir/;
use File::Copy;

desc "Create remote git repository and install push hooks";
task 'setup', sub {

# -- one options
# git-path : remote folder where the git repository will be initiated,  by default it
#            will be git inside the user's home folder
    my ($param) = @_;
    my $git_path = $param->{'git-path'} || '$HOME/git';
    set git_path => $git_path;

    ## -- create a folder and give sticky permission
    if ( !is_dir($git_path) ) {
        run "mkdir -p $git_path";
    }
    chmod "g+ws", $git_path;

    ## -- init a bare repository
    if ( can_run 'git' ) {
        say run "git init --share=group $git_path";
        run 'git config --bool receive.denyNonFastForwards false';
        run 'git config receive.denyCurrentBranch ignore';

        do_task 'git:deploy:hooks';
    }
    else {
        warn "git is not installed in remote server\n";
    }
};

desc 'Install git hooks in the remote repository';
task 'hooks' => sub {

# -- takes the following options
# deploy-to : remote folder where the web application will be deployed,  default is
#             gitweb inside the user's home folder.
# perl-version : default is perl-5.10.1
# deploy-mode : should be either of fcgi or reverse-proxy,  default is reverse-proxy
# hook : post-receive hook file,  default is hooks/post-receive.template
    my ($param) = @_;
    my $deploy_mode = $param->{'deploy-mode'}  || 'reverse-proxy';
    my $perlv       = $param->{'perl-version'} || 'perl-5.10.1';

    my $home = say run 'echo $HOME';
    my $deploy_path = $param->{'deploy-to'}    || $home.'/gitweb';
    my $remote_file
        = $home . '/' . get('git_path') . '/.git/hooks/post-receive';
    my $hook_file;
    if ( defined $param->{hook} ) {
        $hook_file = $param->{hook};
    }
    else {
        if ( -e 'Rexfile' or -e catdir( curdir(), get 'task_folder' ) ) {
            $hook_file = catfile(
                curdir(), get 'task_folder',
                'hooks',  'post-receive.template'
            );
        }
        else {
            $hook_file = catfile( curdir, 'hooks', 'post-receive.template' );
        }
    }
    my $content = do { local ( @ARGV, $/ ) = $hook_file; <> };
    warn $content, "\n";

    # -- replace template variable if exist
    $content =~ s{<%=\s?(deploy-to)\s?%>}{$deploy_path};
    $content =~ s{<%=\s?(perl-version)\s?%>}{$perlv};
    $content =~ s{<%=\s?(deploy-mode)\s?%>}{$deploy_mode};

    my $fh = file_write $remote_file;
    $fh->write($content);
    $fh->close;

    chmod '+x', $remote_file;
};

desc 'Create mojolicious deployment scripts for your web application';
task 'init' => sub {
    my $to_dir = catdir( curdir(), updir(), 'deploy' );
    my $from_dir = catdir( curdir(), 'templates' );
    ## -- making guess
    if ( -e 'Rexfile' or -e catdir( curdir(), get 'task_folder' ) ) {
        $to_dir = catdir( curdir(), 'deploy' );
        $from_dir = catfile( curdir(), get 'task_folder', 'templates' );
    }
    LOCAL => sub {
        if ( !-e $to_dir ) {
            mkdir $to_dir;
        }
        opendir my $dir, $from_dir or die "cannot open dir:$!";
        my @files = grep { !/^\.{,2}/ } readdir $dir;
        for my $name (@files) {
            ( my $wo_ext = $name ) =~ s/\.sh$//;
            copy catfile( $from_dir, $name ), catfile( $to_dir, $wo_ext )
                or die "Copy failed $!";
            chmod 0744, catfile( $to_dir, $wo_ext );
        }
    };
};

1;    # Magic true value required at end of module
