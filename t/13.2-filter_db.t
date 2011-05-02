use strict;
use warnings;
use Test::More;

my $has_timepiece;

BEGIN {
    $ENV{ANSI_COLORS_DISABLED} = 1;
    use File::HomeDir::Test;
};

use Data::Printer {
    filters => {
        external => [ 'DB' ]
    },
};

eval 'use DBI';
plan skip_all => 'DBI not available' if $@;

my $dir = -d 't' ? 't/' : './';
my $dbh = DBI->connect('dbi:DBM(RaiseError=1):', undef, undef,
        {f_dir => $dir });

is( p($dbh), 'DBM Database Handle (connected) {
    Auto Commit: 1
    Statement Handles: 0
    Last Statement: -
}', 'DBH output'
);
my $sth = $dbh->prepare('CREATE TABLE foo ( bar TEXT, baz TEXT )');
is( p($dbh), 'DBM Database Handle (connected) {
    Auto Commit: 1
    Statement Handles: 1 (0 active)
    Last Statement: CREATE TABLE foo ( bar TEXT, baz TEXT )
}', 'DBH output (after setting statement)'
);

is( p($sth), 'CREATE TABLE foo ( bar TEXT, baz TEXT )', 'STH output' );

$sth->execute;

is( p($sth), 'CREATE TABLE foo ( bar TEXT, baz TEXT )', 'STH output' );

my $sth2 = $dbh->prepare('SELECT * FROM foo WHERE bar = ?');
is( p($dbh), 'DBM Database Handle (connected) {
    Auto Commit: 1
    Statement Handles: 2 (0 active)
    Last Statement: SELECT * FROM foo WHERE bar = ?
}', 'DBH output (after new statement)'
);

$sth2->execute(42);
is( p($sth2), 'SELECT * FROM foo WHERE bar = ?  (bindings unavailable)', 'STH-2 output' );

is( p($dbh), 'DBM Database Handle (connected) {
    Auto Commit: 1
    Statement Handles: 2 (1 active)
    Last Statement: SELECT * FROM foo WHERE bar = ?
}', 'DBH output (after executing new statement)'
);

undef $sth;

$dbh->disconnect;
is( p($dbh), 'DBM Database Handle (disconnected) {
    Auto Commit: 1
    Statement Handles: 1 (1 active)
    Last Statement: SELECT * FROM foo WHERE bar = ?
}', 'DBH output (after disconnecting)'
);


# cleanup
use File::Spec;
foreach my $ext (qw(dir lck pag)) {
    my $file = File::Spec->catfile( $dir, "foo.$ext" );
    if (-e $file) {
        unlink $file;
    }
    else {
        diag("error removing $file");
    }
}
   

done_testing;