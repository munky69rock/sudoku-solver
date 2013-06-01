#!/usr/bin/perl

use strict;
use warnings;

{
	package Sudoku;

	our $COLUMN_NUM;

	sub new {
		my $class  = shift;
		my %args = @_;
		
		my $matrix = [];
		if ($args{file}) {
			$matrix = $class->_parse_file($args{file});
		} elsif ($args{matrix}) {
			$matrix = $args{matrix};
		}
		
		return bless $matrix, $class;
	}

	sub _parse_file {
		my $self = shift;
		my $filename = shift;
		open my $fh, '<', $filename or die $!;
		my $i = 0;
		my $numbers = '';
		while (my $l = <$fh>) {
			$l =~ s/\s//g;
			next if !$l || $l =~ /^#/;
			$numbers .= $l;	
		}
		return $self->_parse_numbers($numbers);
	}

	sub _parse_numbers {
		my $self = shift;
		my $numbers = shift;
		$COLUMN_NUM = sqrt length($numbers);
		my $matrix = [];
		for my $i (0 .. length ($numbers) - 1) {
			my $h = $i % $COLUMN_NUM;
			my $v = int($i/$COLUMN_NUM);
			$numbers =~ s/^(.)//;
			$matrix->[$v][$h] = $1;
		}
		return $matrix;
	}

	sub value {
		my $self = shift;
		my $x = shift;
		my $y = shift;
		my $v = shift;
		return $self->[$y][$x] unless $v;
		$self->[$y][$x] = $v;
	}

	sub horizontal_values {
		my $self = shift;
		my $i = shift;
		return $self->[$i];
	}

	sub vertical_values {
		my $self = shift;
		my $i = shift;
		return [
			map { $self->[$_][$i] } (0 .. $COLUMN_NUM - 1)
		];
	}

	sub block_values {
		my $self = shift;
		my $x = shift;
		my $y = shift;
		my $blocks = Sudoku::Coord->new($x, $y)->block;
		my $ret = [];
		for my $c (@$blocks) {
			push @$ret, $self->value($c->x, $c->y);
		}
		return $ret;
	}

	sub render {
		my $self = shift;
		my $devider  = '+ - ' x $COLUMN_NUM . "+\n";
		my $devider2 = '+   ' x $COLUMN_NUM . "+\n";
		my $view = $devider;
		my $ln  = 0;
		for my $line (@$self) {
			$view .= '|';
			my $col = 0;
			for my $number (@$line) {
				$col++;
				$view .= " $number " . ($col % 3 == 0 ? '|' : ' ');
			}
			$ln++;
			$view .= "\n" . ($ln % 3 == 0 ? $devider : $devider2);
		}
		print $view;
	}

	1;
}

{
	package Sudoku::Coord;

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
}

{
	package Sudoku::Solver;

	use base q(Sudoku);
	use List::MoreUtils qw(uniq);

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
		$self->solve_one;
		for my $n (2 .. $Sudoku::COLUMN_NUM) {
			my $i = 0;
			for my $coord (@{$self->blank_coord}) {
				my $exp = $self->expected_values($coord);
				if (@$exp == $n) {
					for my $e (@$exp) {
						my $clone = $self->clone;
						my $solved = 0;
						eval {
							$clone->value($coord->x, $coord->y, $e);
							$clone->solve_one;
							unless (@{$clone->blank_coord}) {
								$solved = 1;
							}
						};
						if ($@) {
							$exclude->{$coord->x}{$coord->y}{$e} = 1;
						} elsif ($solved) {
							return $clone;
						}
					}
				}
			}
		}
	}

	sub expected_values {
		my $self = shift;
		my $basis_coord = shift;
		my %used = map { $_ => 1 } grep { $_ } uniq(
			@{$self->vertical_values($basis_coord->x)},
			@{$self->horizontal_values($basis_coord->y)},
			@{$self->block_values($basis_coord->x, $basis_coord->y)},
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
}

sub main {
	my $file = shift @ARGV;
	die if !$file || !-e $file;

	my $sudoku = Sudoku::Solver->new( file => $file );

	print "[Problem]\n";
	$sudoku->render;
	print "\n";

	if (my $answer = $sudoku->solve) {
		print "[Answer]\n";
		Sudoku->new( matrix => $answer )->render;
	} else {
		die 'Could not solve the problem ...';
	}
}

main;
