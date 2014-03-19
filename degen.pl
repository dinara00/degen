#! /usr/local/bin/perl5.18.2

use common::sense;
use v5.10.1;
use lib '.';
use degen::database;

my $db = degen::database->new;


my $go = 1;

while ( $go ) {

	print "Command: ";
	my $cmd = <STDIN>;

	for ( $cmd ) {
		when (/^items/) {
			say "Defined items:\n";
			foreach my $item ( $db->get_items ) {
				say "\t$item->{name}\t$item->{description}";
			}
		}
		when (/^quit/) {
			$go = 0;
		}
	}

}

say "bye";

exit;

