package Sudoku::Solver;

use strict;
use warnings;

use base q(Sudoku);
use List::MoreUtils qw(uniq);
use Data::Dump qw(dump);

my $exclude = {};

sub clone {
	my $new = [];
	for my $i (0 .. $#{$_[0]}) {
		for my $j (0 .. $#{$_[0]->[$i]}) {
			$new->[$i][$j] = $_[0]->[$i][$j];
		}
	}
	return "@{[ref $_[0]]}"->new( matrix => $new );
}

sub solve_one {
	my $self = shift;
	my $sum = 0;
	while (1) {
		my $i = 0;
		for my $coord (@{$self->blank_coord}) {
			my $exp = $self->expected_values($coord);
			$exp = [grep { !$exclude->{$coord->x}{$coord->y}{$_} } @$exp];
			if (@$exp == 1) {
				$self->value($coord->x, $coord->y, $exp->[0]);
				$i++;
			}
			elsif (@$exp == 0) {
				die 'something wrong.';
			}
		}
		$sum += $i;
		last unless $i;
	}
	return $sum;
}

sub solve {
	my $self = shift;
	my $i = 0;
	for my $n (1 .. $Sudoku::COLUMN_NUM) {
		for my $coord (@{$self->blank_coord}) {
			my $exp = $self->expected_values($coord);
			if (@$exp == $n) {
				for my $e (@$exp) {
					my $sudoku = $n == 1 ? $self : $self->clone;
					my $solved = 0;
					eval {
						$sudoku->value($coord->x, $coord->y, $e);
						$sudoku->solve_one;
						unless (@{$sudoku->blank_coord}) {
							$solved = 1;
						}
					};
					if ($@) {
						$exclude->{$coord->x}{$coord->y}{$e} = 1;
						dump $exclude;
					} elsif ($solved) {
						return $sudoku;
					}
				}
			}
		}
		$i++;
		print "$i\n";
	}
}

sub expected_values {
	my $self = shift;
	my $basis_coord = shift;
	my %used = map { $_ => 1 } grep { $_ } uniq(
		@{$self->vertical_values($basis_coord->x)},
		@{$self->horizontal_values($basis_coord->y)},
		@{$self->block_values($basis_coord->x, $basis_coord->y)},
		$exclude->{$basis_coord->x} && $exclude->{$basis_coord->x}{$basis_coord->y} ? keys %{$exclude->{$basis_coord->x}{$basis_coord->y}} : (),
	);
	return [
		grep { !exists $used{$_} } (1 .. $Sudoku::COLUMN_NUM)
	];
}

sub blank_coord {
	my $self = shift;
	my $ret = [];
	for my $i (0 .. $#{$self}) {
		for my $j (0 .. $#{$self->[$i]}) {
			push @$ret, Sudoku::Coord->new($j, $i) unless $self->[$i][$j];
		}
	}
	return $ret;
}

sub filled_coord {
	my $self = shift;
	my $ret = [];
	for my $i (0 .. $#{$self}) {
		for my $j (0 .. $#{$self->[$i]}) {
			push @$ret, Sudoku::Coord->new($j, $i) if $self->[$i][$j];
		}
	}
	return $ret;
}

1;

