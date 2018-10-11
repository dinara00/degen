#! /usr/local/bin/perl
use common::sense;
use Data::Dumper qw(Dumper);

$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Indent = 2;

foreach my $dice_spec ( @ARGV ) {

	my ($count,$sides) = split /d/, $dice_spec;

	my %values = &valuetize($sides, $count);

	foreach my $k ( sort { $a <=> $b } keys %values ) {
		say "| $k | " . ( "x" x $values{$k} ) . " |";
	}

}

exit;

sub valuetize {

	my ($sides, $count) = @_;

	my %values;

	my @rolls;

	for my $index ( 1 .. ($sides ** $count) ) {
		my @roll;
		my $superindex = $index - 1;
		for my $die ( 1 .. $count ) {
			push @roll, ( $superindex % $sides ) + 1;
			$superindex = int ( $superindex / $sides );
		}
		push @rolls, \@roll;
	}

	foreach my $r ( @rolls ) {
		my $sum;
		map { $sum += $_ } @$r;
		$values{$sum}++;
	}

	return %values;
printf
}

