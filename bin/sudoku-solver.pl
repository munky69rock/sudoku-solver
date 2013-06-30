#!/usr/bin/perl

use strict;
use warnings;

use Path::Tiny;
use File::Spec;

use lib File::Spec->catdir( path(__FILE__)->absolute->dirname, '..', 'lib' );
use Sudoku;
use Sudoku::Solver;

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
