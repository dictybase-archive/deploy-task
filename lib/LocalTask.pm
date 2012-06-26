package LocalTask;
use strict;

sub rpms {
    my ( $class, $folder ) = @_;
    my @rpms = glob("$folder/oracle-instantclient-*.rpm");
    die
        "did not get any oracle instantclient rpm(s) from $folder !!!!\n"
        if scalar @rpms == 0;
    return @rpms;
}

1;    # Magic true value required at end of module

