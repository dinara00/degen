package degen::database;

use common::sense;
use DBI;

sub new {

	my $self = {
		dbh => undef,
	};

	$self->{dbh} = DBI->connect('dbi:SQLite:database=degen.db');

	bless $self;

}

1;
