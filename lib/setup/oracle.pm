package  setup::oracle;
use strict;
use Rex -base;
use Rex::Commands::Run;
use Rex::Commands::Fs;
use Rex::Commands::Upload;
use Rex::Commands::File;

desc
    'upload a local(--file=[]) tnsnames template file with the provided (--host=) and (--sid=)';
task 'tnsnames' => sub {
    my ($param) = @_;
    for my $v (qw/host sid file/) {
        die "no $v is given\n" if not exists $param->{$v};
    }

    my $content = do { local ( @ARGV, $/ ) = $param->{file}; <> };
    $content =~ s{<%=\s?(sid)\s?%>}{$param->{sid}};
    $content =~ s{<%=\s?(service)\s?%>}{$param->{sid}};
    $content =~ s{<%=\s?(orahost)\s?%>}{$param->{host}};

    my $infh = file_read('/etc/profile.d/oracle.sh');
    my $source = $infh->read_all;
    $infh->close;

    if ($source =~ /ORACLE_HOME=(\S+)/) {
    	my $outdir = "$1/network/admin";
    	mkdir $outdir if !is_dir($outdir);
    	my $outfh = file_write("$outdir/tnsnames.ora");
    	$outfh->write($content);
    	$outfh->close;
    }
};

1;
