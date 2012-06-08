package  setup::apache;
use strict;
use Rex -base;
use Rex::Commands::Run;
use Rex::Commands::Fs;
use Rex::Commands::Upload;
use Rex::Commands::File;

desc 'add apache envvars from a local file(--file=[])';
task 'envvars' => sub {
    my ($param) = @_;
    die "no input file (--file) is given\n" if not exists $param->{file};

    my $content = do { local ( @ARGV, $/ ) = $param->{file}; <> };
    my $fh = file_append('/etc/sysconfig/httpd');
    $fh->write($content);
    $fh->close;

    if ( $content =~ /WEBAPPS_DIR=(\S+)/ ) {
        my $file = '/etc/httpd/conf.d/perl.conf';
        if ( is_file($file) ) {
            my $fh = file_append($file);
            $fh->write("PerlSetEnv WEBAPPS_DIR $1");
            $fh->close;
        }
    }
};

desc
    'upload a local(--file=[]) apache configuration file(--name=[vhost_site.conf])';
task 'vhost' => sub {
    my ($param) = @_;
    die "no input file (--file) is given\n" if not exists $param->{file};
    my $name = $param->{name} || 'vhost_site.conf';
    my $content = do { local ( @ARGV, $/ ) = $param->{file}; <> };
    my $fh = file_write("/etc/httpd/conf.d/$name");
    $fh->write($content);
    $fh->close;
};

desc 'start apache2 and make sure it gets started at boot';
task 'startup' => sub {
    service 'apache2' => 'start';
    service 'apache2' => 'ensure', 'started';
};

1;
