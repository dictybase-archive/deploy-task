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

1;