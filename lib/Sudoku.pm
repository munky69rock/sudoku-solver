package Sudoku;

use strict;
use warnings;
use version; our $VERSION = version->declare("v0.0.1");

use Sudoku::Coord;

our $COLUMN_NUM = 0;

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
	return;
}

1;
