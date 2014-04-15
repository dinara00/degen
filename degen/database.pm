package degen::database;

use common::sense;
use DBI;
use Data::Dumper qw(Dumper);

use degen::room;

sub new {

	my $self = {
		dbh   => undef,
		rooms => {},
		items => {},
	};

	$self->{dbh} = DBI->connect('dbi:SQLite:database=degen.db');

	bless $self;

}

sub uid {

	my ( $self, $length ) = @_;
	$length = $self->{uid_length} unless defined($length);

	my $uid = '';
	my @range = ('a'..'z' , '0' .. '9');

	my $last = undef;
	do {
		my $char = $range[int(rand(scalar(@range)))];
		if ( $char ne $last ) {
			$uid .= $char;
			$last = $char;
		}
	} until ( length($uid) == $length );

	return $uid;

}

sub set_uid_length {
	my ( $self, $length );
	$self->{uid_length} = $length;
}

sub load_rooms {
	my $self = shift;
	my @items = $self->load_items_query('select room_id as id, name, length, width, height from rooms');
	$self->{rooms} = { map { $_->{id} => $_ } @items };
	return values %{$self->{rooms}};
}

sub load_items {
	my $self = shift;
	$self->{items} = $self->load_items_query_hashed('select item_id as id, name, description from items order by name asc');
	return values %{$self->{items}};
}

sub load_perks {
	my $self = shift;
	$self->{perks} = $self->load_items_query_hashed('select perk_id as id, * from perks');
	return values %{$self->{items}};
}

sub load_players {
	my ($self, $room_id) = @_;
	my $query = qq{
	select players.player_id as id, players.* , characters.*
	from players
	join characters using (char_id)
	};
	$query .= " where room_id = '$room_id'" if $room_id;
	$self->{players} = $self->load_items_query_hashed($query);

	my $qperks = 'select * from player_perks';
	my @perks = $self->load_items_query($qperks);
	foreach my $player ( values %{ $self->{players} } ) {
		$player->{perks} = {};
		foreach my $pp ( @perks ) {
			$player->{perks}->{$pp->{perk_id}} = $self->{perks}->{$pp->{perk_id}};
		}
	}

	foreach my $player ( values %{$self->{players}} ) {
		$player->{tech} = {};
		foreach my $tech_id ( keys %{$self->{tech}} ) {
			next unless $self->check_player_has_tech($player->{id}, $tech_id);
			$player->{tech}->{$tech_id} = $self->{tech}->{$tech_id};
		}
	}

	return values %{$self->{players}};
}

sub check_player_has_tech {
	my ( $self, $player_id, $tech_id ) = @_;
	my @reqs = values %{ $self->{tech}->{$tech_id}->{req} };
	return 1 unless scalar @reqs;
	foreach my $req ( @reqs ) {
		return 0 if $req->{perk_id} && !exists $self->{players}->{$player_id}->{perks}->{$req->{perk_id}};
	}

	return 1;
}

sub load_tech {
	my $self = shift;
	my $query = qq{
		select tech_id as id,tech.*
		from tech
	};
	$self->{tech} = $self->load_items_query_hashed($query);

	my $q2 = qq{select tech_req.tech_id,req.* from req join tech_req using (req_id)};
	my @reqs = $self->load_items_query($q2);

	foreach my $tech ( values %{ $self->{tech} } ) {
		$tech->{req} = { map { $_->{req_id} => $_ } grep { $_->{tech_id} eq $tech->{id} } @reqs };
	}

	return values %{$self->{tech}};
}

sub load_items_query_hashed {
	my ( $self, $query, $params ) = @_;
	my @items = $self->load_items_query($query, $params);
	my %hash = map { $_->{id} => $_ } @items;
	return \%hash;
}

sub load_items_query {

	my ( $self, $query, $params ) = @_;

	my @items;

	my $q = $self->{dbh}->prepare($query);
	$q->execute(@$params);

	while ( my $item = $q->fetchrow_hashref ) {
		push @items, $item;
	}

	$q->finish;

	return @items;
}

sub get_stat_bonus { my ( $self, $stat ) = @_; $stat-=8; return $stat>0 ? int($stat/2) : 0  }

sub get_tech_matrix {
	my ( $self, $player_id_a, $player_id_b ) = @_;
	my @tech;
	my $a = $self->{players}->{$player_id_a};
	my $b = $self->{players}->{$player_id_b};
	foreach my $tech ( values %{ $b->{tech} } ) {
		my $data = {
			tech => $tech,
			valid => 1,
			difficulty => $tech->{difficulty},
			notes => '',
		};
		# base difficulty is the differential bonus in STR and DEX
		$data->{difficulty} -= $self->get_stat_bonus($a->{str});
		$data->{difficulty} -= $self->get_stat_bonus($a->{dex});
		$data->{difficulty} += $self->get_stat_bonus($b->{str});
		$data->{difficulty} += $self->get_stat_bonus($b->{dex});
		#$data->{valid} = 0 if $data->{difficulty} > 20;

		push @tech, $data;
	}
	return @tech;
}

sub die_roll {
	my ( $self, $sides, $count ) = @_;
	my @rolls;
	foreach my $i ( 1 .. $count ) {
		push @rolls, int(rand($sides)) + 1;
	}
	return @rolls;
}

1;
