#! /usr/local/bin/perl5.18.2

use v5.10.1;
use common::sense;
use Term::ReadLine;
use lib '.';
use degen::database;
use Data::Dumper qw(Dumper);

my $db = degen::database->new;


my $go = 1;
my $room;
my $cmd;

my $term = new Term::ReadLine 'degen';
my $attr = $term->Attribs;
$attr->{completion_function} = sub {
	my ( $text, $line, $start ) = @_;
	my @commands = qw {uid items rooms reload uid};
	return @commands;
};

my $prompt = 'degen> ';

&reload_all();

while ( defined( $cmd = $term->readline($prompt) ) ) {
	local $, = "\t";

	given ( $cmd ) {
		when (/^reload/) {
			&reload_all;
		}
		when (/^setroom\s*(\S*)/) {
			if ( $1 ) {
				if ( exists $db->{rooms}->{$1} ) {
					$room = $db->{rooms}->{$1};
					say "Now in room \e[33m$room->{name}\e[m";
					&reload_all();
				}
				else {
					say "Room $1 does not exist";
				}
			}
			else {
				say $room->{id}, $room->{name};
			}
		}
		when (/^players/) {
			my @players = values %{$db->{players}};
			foreach my $player ( @players ) {
				say "$player->{id}\t$player->{name}";
			}
			say "No players" unless scalar @players;
		}
		when (/^(am|attackmatrix) (\S+) (\S+)/) {
			my @tech = $db->get_tech_matrix($2,$3);
			my $fmt = "%-5s %-20s %-10s %s\n";
			if ( scalar @tech ) {
				printf $fmt, "id", "nombre", "dificultad";
			}
			else {
				say "Ninguna técnica aplicable";
			}
			foreach my $tt ( @tech ) {
				next unless $tt->{valid};
				printf $fmt, (
					$tt->{tech}->{id},
					$tt->{tech}->{name},
					$tt->{difficulty},
					$tt->{notes}
				);
			}
		}
		when (/^i(tems)?/) {
			my @items = values %{$db->{items}};
			foreach my $item ( @items ) {
				say "$item->{id}\t$item->{name}\t$item->{description}";
			}
			say "No items" unless scalar @items;
		}
		when (/^uid/) {
			say $db->uid;
		}
		when (/^r(ooms)?/ ) {
			my @rooms = values %{$db->{rooms}};
			foreach ( @rooms ) {
				say $_->{id}, $_->{name}, $_->{description};
			}
			say "No rooms" unless scalar @rooms;
		}
		when (/(\d+)?d(\d+)/) {
			my $sides = $2;
			my $count = $1 ? $1 : 1;
			my @rolls = $db->die_roll($sides, $count);
			my $sum = 0;
			my $fails = 0;
			my $criticals = 0;
			foreach my $r ( @rolls ) {
				if ( $r == 1 ) {
					say "\e[31m$r\e[m";
					$fails++;
				}
				elsif ( $r == $sides ) {
					say "\e[32m$r\e[m";
					$criticals++;
				}
				else {
					say $r;
				}
				$sum += $r;
			}
			say "Total: $sum\t\t$fails fails\t$criticals criticals";
		}
		when (/^dump (.*)$/) {
			eval "say Dumper($1)";
		}
		default {
			say "Command not understood: $cmd";
		}
	}

}

say "bye";

exit;

sub reload_all {

	$db->load_rooms;
	$db->load_items;
	$db->load_tech;
	$db->load_perks;
	$db->load_players( $room ? $room->{id} : undef );

}
