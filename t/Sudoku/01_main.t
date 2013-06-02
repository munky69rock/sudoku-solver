#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use lib qw/lib/;
use Sudoku;
use Data::Dump qw(dump);
use Clone qw(clone);

my $matrix = [
	[1,5,0,0,8,6,0,7,0],
	[7,0,8,9,0,0,0,0,0],
	[0,9,0,5,0,0,0,8,1],
	[9,0,0,0,0,8,1,0,6],
	[0,0,1,0,2,0,0,9,0],
	[0,7,5,6,0,0,2,0,0],
	[5,0,6,0,4,0,0,2,0],
	[3,0,0,1,0,2,5,0,0],
	[0,4,0,8,0,0,0,0,9],
];

subtest 'new' => sub {
	subtest 'parse numbers' => sub {
		my $numbers =
			"150086070708900000090500081900008106001020090075600200506040020300102500040800009";
		is_deeply(Sudoku->_parse_numbers($numbers), $matrix);
	};

	subtest 'parse file' => sub {
		my $tmpfile = "/tmp/test-Sudoku.pm";
		
		my $test = sub {
			my $data = shift;
			open my $tmp, '>', $tmpfile or die "$!";
			print $tmp $data;
			close $tmp;
			is_deeply(Sudoku->_parse_file( $tmpfile ), $matrix);
			unlink $tmpfile if -e $tmpfile;
		};
		
		my $raw_data = <<EOT;
150086070
708900000
090500081
900008106
001020090
075600200
506040020
300102500
040800009
EOT
		my $raw_data_with_spaces = <<EOT;

$raw_data

EOT
		my $raw_data_with_comments = <<EOT;
# this is comment

$raw_data
EOT
		$test->($raw_data);
		$test->($raw_data_with_spaces);
		$test->($raw_data_with_comments);
	};
};

subtest 'values' => sub {
	my $sudoku = sub {
		clone(Sudoku->new( matrix => $matrix ));
	};

	subtest 'value' => sub {
		my $s = $sudoku->();
		is($s->value(0,0), 1);
		is($s->value(1,1,5), 5);
	};

	subtest 'horizontal_values' => sub {
		my $s = $sudoku->();
		is_deeply($s->horizontal_values(1), [7,0,8,9,0,0,0,0,0]);
	};

	subtest 'vertical_values' => sub {
		my $s = $sudoku->();
		is_deeply($s->vertical_values(1), [5,0,9,0,0,7,0,0,4]);
	};

	subtest 'block_value' => sub {
		my $s = $sudoku->();
		is_deeply($s->block_values(8,8), [0,5,0,2,0,0,0,0,9]);
	};

};

done_testing;
