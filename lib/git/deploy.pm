package git::deploy;

use strict;
use Rex -base;
use Rex::Commands::Run;
use Rex::Commands::Fs;
use Rex::Commands::Gather;
use Rex::Commands::File;
use File::Spec::Functions qw/catfile curdir updir catdir rel2abs/;
use File::Copy;
use File::Basename;

sub _infer_project_name {
    return if get 'project_name';

    my $task_folder = get 'task_folder';
    if ( -e 'Rexfile' or -e catdir( curdir(), $task_folder ) ) {
        set project_name => basename( rel2abs( curdir() ) );
    }
    else {
        die
            "could not get **project name**: rex must be run from the project directory!!!\n";
    }
}

sub _get_remote_folder {
    my ($param) = @_;
    my $remote_folder = $param->{'remote-folder'} || 'hushhush';
    $remote_folder .= '/' . get 'project_name';
    return $remote_folder;
}

desc
    'upload config(--config=[])  file in remote folder(--remote-folder=[${HOME}/hushush])';
task 'upload-config' => sub {
    my ($param) = @_;
    die "no config(--config=) file given\n" if not exists $param->{config};

    my $remote_folder = _get_remote_folder($param);
    if ( !is_dir($remote_folder) ) {
        mkdir $remote_folder;
    }
    my $deploy_mode = run 'echo $MOJO_MODE';
    if ( $? != 0 ) {
        $deploy_mode = 'production';
    }

    my $remote_file = $remote_folder . '/' . $deploy_mode . '.yml';
    upload $param->{config}, $remote_file;
};

desc "Create remote git repository and install push hooks";
task 'setup', sub {

# -- one options
# git-path : remote folder where the git repository will be initiated,  by default it
#            will be git inside the user's home folder
    my ($param) = @_;
    my $git_path = $param->{'git-path'} || 'git';
    $git_path .= '/' . get 'project_name';
    set git_path => $git_path;

    ## -- create a folder and give sticky permission
    if ( !is_dir($git_path) ) {
        run "mkdir -p $git_path";
    }
    chmod "g+ws", $git_path;

    ## -- init a bare repository
    if ( can_run 'git' ) {
        run "git init --share=group $git_path";
        run
            "cd $git_path && git config --bool receive.denyNonFastForwards false";
        run "cd $git_path && git config receive.denyCurrentBranch ignore";

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
# remote-config-folder : to look for encrypted config file with sensitive information
    my ($param) = @_;
    my $deploy_mode = $param->{'deploy-mode'}  || 'reverse-proxy';
    my $perlv       = $param->{'perl-version'} || 'perl-5.10.1';

    my $home        = run 'echo $HOME';
    my $deploy_path = $param->{'deploy-to'}
        || $home . '/webapps';
    $deploy_path .= '/' . get 'project_name';
    if ( !is_dir($deploy_path) ) {
        run "mkdir -p $deploy_path";
        chmod 'g+ws', $deploy_path;
    }

    my $remote_file = get('git_path') . '/.git/hooks/post-receive';
    my $hook_file;
    if ( defined $param->{hook} ) {
        $hook_file = $param->{hook};
    }
    else {
        my $task_folder = get 'task_folder';
        $hook_file = catfile( curdir(), $task_folder, 'hooks',
            'post-receive.template' );
    }
    my $content = do { local ( @ARGV, $/ ) = $hook_file; <> };

    # -- replace template variable if exist
    $content =~ s{<%=\s?(deploy-to)\s?%>}{$deploy_path};
    $content =~ s{<%=\s?(perl-version)\s?%>}{$perlv};
    $content =~ s{<%=\s?(deploy-mode)\s?%>}{$deploy_mode};

    if ( exists $param->{'remote-config-folder'} ) {
        $content
            =~ s{<%=\s?(enc-config-folder)\s?%>}{$param->{'remote-config-folder'}};
    }

    my $fh = file_write $remote_file;
    $fh->write($content);
    $fh->close;

    chmod '+x', $remote_file;
};

desc 'Create mojolicious deployment scripts for your web application';
task 'init' => sub {
    LOCAL {
    	my $task_folder = get 'task_folder';
        my $to_dir = catdir( curdir(), 'deploy' );
        my $from_dir = catfile( curdir(), $task_folder, 'templates' );
        if ( !-e $to_dir ) {
            mkdir $to_dir;
        }
        opendir my $dir, $from_dir or die "cannot open dir:$!";
        my @files = grep { !/^\.\.?$/ } readdir $dir;
        for my $name (@files) {
            ( my $wo_ext = $name ) =~ s/\.sh$//;
            copy catfile( $from_dir, $name ), catfile( $to_dir, $wo_ext )
                or die "Copy failed for $name to $wo_ext $!";
            chmod '+x', catfile( $to_dir, $wo_ext );
        }
    }
};

before 'git:deploy:setup'         => sub { _infer_project_name() };
before 'git:deploy:hooks'         => sub { _infer_project_name() };
before 'git:deploy:upload-config' => sub { _infer_project_name() };

1;    # Magic true value required at end of module
