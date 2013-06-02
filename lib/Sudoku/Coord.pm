package Sudoku::Coord;

use strict;
use warnings;

use Sudoku;

sub new {
	my $class = shift;
	my ($x, $y) = ref $_[0] eq 'ARRAY' ? @{$_[0]} : @_;
	return bless +{
		x => $x,
		y => $y,
	}, $class;
}

sub x { $_[0]->{x} }
sub y { $_[0]->{y} }

sub vertical {
	my $self = shift;
	return [
		map {
			Sudoku::Coord->new($self->x, $_)
		} (0 .. $Sudoku::COLUMN_NUM - 1)
	];
}

sub horizontal {
	my $self = shift;
	return [
		map {
			Sudoku::Coord->new($_, $self->y)
		} (0 .. $Sudoku::COLUMN_NUM - 1)
	];
}

sub block {
	my $self = shift;
	my $x = int($self->x() / 3) * 3;
	my $y = int($self->y() / 3) * 3;

	my $ret = [];
	for my $i ($x .. $x + 2) {
		for my $j ($y .. $y + 2) {
			push @$ret, Sudoku::Coord->new($i, $j);
		}
	}
	
	return $ret;
}

1;
