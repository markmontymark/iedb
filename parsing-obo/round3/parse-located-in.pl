#!/usr/bin/perl


use strict;
use warnings;
use v5.14;

my %terms;
my %terms_del;
my %kids;
for(<DATA>)
{
	s/\s+//g;
	$kids{$_} = 0;
}

my $n_terms = 0;
my $n_kids_found = 0;
my $n_ids_not_in_kids = 0;

my %ancestors = ();

my $in_terms = 0;
my @term_lines = ();
open F,$ARGV[0];
open K,">$ARGV[0].round3.located-in" || die "Can't open $ARGV[0].round3.located-in, $!\n";
while(<F>)
{
	if($in_terms)
	{
		last if /^\s*\[TYPEDEF\]/i;

		if(/^\s*$/)
		{
			push @term_lines,$_;
			$n_terms++;
			&collectTerm(\@term_lines,$n_terms);
			@term_lines = ();
		}
		else
		{
			push @term_lines,$_;
		}
	}
	elsif(/^\s*\[TERM\]/i)
	{
		$in_terms = 1;
		push @term_lines,$_;
	}
}
close F;
close K;

say "n terms: $n_terms";
say "n terms we care about: " . scalar(keys %kids);
say "n terms we found: $n_kids_found";

sub collectTerm
{
	my($lines) = @_;
	my $id;
	for(@$lines)
	{
		## relationship: located_in GAZ:00000465
		if(/(relationship\s*:\s*located_in\s*GAZ:\d+)/i)
		{
			$id = $1;
			$id =~ s/\s+//g;
			if(exists $kids{$id})
			{
				$n_kids_found++;
				print K @$lines,"\n";
				if($kids{$id} == 0)
				{
					$kids{$id} = 1;
					return;
				}
			}
		}
	}
}

__DATA__
relationship: located_in GAZ:00000465
relationship: located_in GAZ:00000588
relationship: located_in GAZ:00002891
relationship: located_in GAZ:00000556
relationship: located_in GAZ:00000460
relationship: located_in GAZ:00000464
relationship: located_in GAZ:00000555
relationship: located_in GAZ:00000458
relationship: located_in GAZ:00000553
relationship: located_in GAZ:00000459
relationship: located_in GAZ:00002472
relationship: located_in GAZ:00000587
relationship: located_in GAZ:00002637
relationship: located_in GAZ:00000554
relationship: located_in GAZ:00000559
relationship: located_in GAZ:00002464
relationship: located_in GAZ:00002471
relationship: located_in GAZ:00002846
relationship: located_in GAZ:00002467
relationship: located_in GAZ:00002466
relationship: located_in GAZ:00281547
