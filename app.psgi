#!/usr/bin/env perl

use strict;
use warnings;

use Path::Tiny;

use File::Spec;
use Text::Xslate;
use HTML::FillInForm::Lite;
use Plack::Request;
use Data::Dump qw(dump);

my $base_dir; BEGIN { $base_dir = path(__FILE__)->absolute->dirname }
use lib File::Spec->catdir($base_dir, 'lib');

use Sudoku;
use Sudoku::Solver;

my $tx = Text::Xslate->new(
	cache_dir => File::Spec->catdir($base_dir, '.xslate_cache'),
);
my $form = HTML::FillInForm::Lite->new;

my $app = sub {
	my $env = shift;
	my $req = Plack::Request->new($env);
	my $params = $req->parameters->as_hashref;
	my $template = create_template(
		caption => $params->{exec} ? 'Answer' : 'Problem',
	);
	if ($params->{exec}) {
		my $matrix = [];
		for my $k (grep { /^coord/ } keys %$params) {
			my ($x, $y) = ($k =~ /coord-(\d+)-(\d+)/);
			my $v = $params->{$k} || 0;
			$matrix->[$y][$x] = $v;
		}
		my $answer = Sudoku::Solver->new( matrix => $matrix )->solve;
		my $data = {};
		for my $i (0 .. 8) {
			for my $j (0 .. 8) {
				$data->{"coord-$i-$j"} = $answer->[$j][$i];
			}
		}
		$template = $form->fill(\$template, $data);
	} else {
		my $default = create_default_data();
		my $data = {};
		for my $i (0 .. 8) {
			for my $j (0 .. 8) {
				$data->{"coord-$i-$j"} = $default->value($i, $j);
			}
		}
		$template = $form->fill(\$template, $data);
	}

	return [
		200,
		[ 'Content-Type' => 'text/html' ],
		[ $tx->render_string($template) ],
	];
};

sub create_default_data {
	Sudoku->new( file => File::Spec->catfile($base_dir, 'sample.txt'));
}

sub create_template { <<HTML }
<!DOCTYPE HTML>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>SUDOKU SOLVER</title>
  <link href="//netdna.bootstrapcdn.com/twitter-bootstrap/2.3.2/css/bootstrap-combined.min.css" rel="stylesheet">
  <script src="//netdna.bootstrapcdn.com/twitter-bootstrap/2.3.2/js/bootstrap.min.js"></script>
  <style type="text/css">
    body {
      padding-top: 40px;
      padding-bottom: 40px;
      background-color: #f5f5f5;
    }
    thead, tbody, tr, th, td, input[type=number] {
      -webkit-box-sizing: border-box;
      -moz-box-sizing: border-box;
      box-sizing: border-box;
    }
    input[type=number] {
      width: 40px;
      height: 40px;
      border: none;
      margin: 0;
      padding: 0;
	  text-align: center;
    }
	table {
	  border: 1px solid #999 !important;
	}
    th, td {
      width: 40px;
      height: 40px;
      padding: 0 !important;
    }
	.table-bordered th:nth-child(3n + 1), .table-bordered td:nth-child(3n + 1) {
	  border-left: 1px solid #999 !important;
	}
	.table tr:nth-child(3n + 1) tr, .table tr:nth-child(3n + 1) td {
	  border-top: 1px solid #999 !important;
	}
	#main {
	  margin: 0 auto;
	  width: 400px;
	  height: 400px;
	}
    .form {
      max-width: 500px;
      padding: 19px 29px 29px;
      margin: 0 auto 20px;
      background-color: #fff;
      border: 1px solid #e5e5e5;
      -webkit-border-radius: 5px;
         -moz-border-radius: 5px;
              border-radius: 5px;
      -webkit-box-shadow: 0 1px 2px rgba(0,0,0,.05);
         -moz-box-shadow: 0 1px 2px rgba(0,0,0,.05);
              box-shadow: 0 1px 2px rgba(0,0,0,.05);
    }
    .form .form-heading,
    .form .checkbox {
      margin-bottom: 10px;
    }
  </style>
</head>
<body>
  <div class="container">
    <form class="form" method="POST">
      <div id="main">
        @{[create_table(@_)]}
      </div>
	  <div style="text-align: center;">
		<button class="btn btn-large btn-primary" type="submit">Solve!</button>
		<input type="hidden" name="exec" value="1"/>
	  </div>
    </form>
  </div>
</body>
</html>
HTML

sub create_table {
	my %params = @_;
	my $table = <<HTML;
<table class="table table-bordered">
<caption>$params{caption}</caption>
HTML
	for my $i (0 .. 8) {
		if ($i == 0) {
			$table .= '<tbody>';
		}
		$table .= '<tr>';
		for my $j (0 .. 8) {
			$table .= <<HTML;
<td>
<input type="number" name="coord-$i-$j" min="0" max="9" value=""/>
</td>
HTML
		}
		$table .= '</tr>';
	}
	$table .= <<HTML;
</tbody>
</table>
HTML
}
