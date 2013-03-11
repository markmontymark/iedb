#!/usr/bin/perl


use strict;
use warnings;
use v5.14;

my %terms;
my %terms_del;
my %kids;
for(<DATA>)
{
	s/^\s+//;
	s/\s+$//;
	$kids{$_} = 0;
}

my $n_terms = 0;
my $n_kids_found = 0;
my $n_ids_not_in_kids = 0;

my %ancestors = ();

my $in_terms = 0;
my @term_lines = ();
open F,$ARGV[0];
open N,">$ARGV[0].round3.fixed";
open K,">$ARGV[0].round3.kids";
while(<F>)
{
	if($in_terms)
	{
		if(/^\s*\[TYPEDEF\]/i)
		{
			$in_terms = 0;
			&keepTerms(1);
			&printTerms;
			print N $_;
			next;
		}
		elsif(/^\s*$/)
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
	else
	{
		print N $_;
	}
}
close F;
close N;
close K;

say "n terms: $n_terms";
say "n terms we care about: " . scalar(keys %kids);
say "n terms we found that we dont care about: $n_ids_not_in_kids";

sub keepTerms
{
	my($ancestry) = @_;

	my $made_a_change = 0;
	#say "keepTerms in with " . scalar(keys %terms) . ' terms';
	for my $id ( keys %terms)
	{
		my $otherIds = $terms{$id}->{otherids};
		for(@$otherIds)
		{
			if((not exists $terms{$_}) and (not exists $terms_del{$_}))
			{
				next;
			}
			if( (not exists $terms{$_}) and (exists $terms_del{$_}) )
			{
				$made_a_change = 1;
				$terms{$_} = $terms_del{$_};
				$ancestors{''.$ancestry} = {} unless exists $ancestors{''.$ancestry};
				$ancestors{''.$ancestry}->{$_} = 0;
				delete $terms_del{$_};
			}
		}
	}
	#say "keepTerms out with " . scalar(keys %terms) . " terms\n\n";
	&keepTerms(++$ancestry) if $made_a_change;
}

sub printTerms
{
	my $in_terms = 0;
	my @term_lines = ();
	open G,$ARGV[0];
	while(<G>)
	{
		if($in_terms)
		{
			if(/^\s*\[TYPEDEF\]/i)
			{
				$in_terms = 0;
				last;
			}
			elsif(/^\s*$/)
			{
				push @term_lines,$_;
				&printTerm(\@term_lines);
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
	close G;
}

sub printTerm
{
	my($lines) = @_;
	my($id) = $lines->[1] =~ m/^\s*id:\s*(\S+)\s*$/;
	return unless exists $terms{$id};
	print N @$lines;
}


sub collectTerm
{
	my($lines,$orderby) = @_;
	my $id;
	my %idsFound = ();
	my $ours = 0;
	for(@$lines)
	{
		## handling id
		if(/^\s*id:\s*(\S+)\s*$/)
		{
			$id = $1;
			if(exists $kids{$id})
			{
				$n_kids_found++;
				$terms{$id} = {orderby => $orderby};
				$ours = 1;
				if($kids{$id} == 0)
				{
					print K @$lines,"\n";
					$kids{$id} = 1;
				}
				else
				{
					print STDERR "found $id again? This shouldn't happen, unless there\n";
				}
			}
			else
			{
				$n_ids_not_in_kids++;
				if(exists $terms_del{$id} )
				{
					say "already found $id";
				}
				else
				{
					$terms_del{$id} = {orderby => $orderby};
				}
			}
		}
		elsif( /(GAZ:\d+)/)
		{
			$idsFound{$1} = 0;
		}
	}
	my @otherIds = keys %idsFound;
	return unless scalar @otherIds > 0;
	
	if($ours)
	{
		$terms{$id}->{otherids} = \@otherIds;
	}
	elsif(exists $terms_del{$id})
	{
		$terms_del{$id}->{otherids} = \@otherIds;
	}
	
}

__DATA__
GAZ:00001092
GAZ:00002978
GAZ:00000457
GAZ:00001095
GAZ:00002928
GAZ:00000465
GAZ:00005863
GAZ:00000463
GAZ:00003734
GAZ:00002828
GAZ:00000905
GAZ:00001093
GAZ:00000588
GAZ:00002891
GAZ:00002825
GAZ:00002845
GAZ:00002929
GAZ:00000556
GAZ:00002641
GAZ:00000567
GAZ:00000460
GAZ:00000464
GAZ:00002937
GAZ:00067144
GAZ:00002940
GAZ:00000907
GAZ:00000908
GAZ:00002936
GAZ:00002894
GAZ:00002839
GAZ:00000466
GAZ:00003727
GAZ:00002476
GAZ:00003101
GAZ:00002650
GAZ:00002747
GAZ:00024383
GAZ:00001101
GAZ:00000591
GAZ:00000911
GAZ:00001108
GAZ:00001105
GAZ:00002852
GAZ:00006899
GAZ:00004399
GAZ:00000912
GAZ:00000555
GAZ:00000458
GAZ:00005246
GAZ:00003922
GAZ:00002932
GAZ:00005861
GAZ:00003944
GAZ:00000913
GAZ:00003923
GAZ:00002955
GAZ:00001104
GAZ:00000553
GAZ:00000459
GAZ:00002472
GAZ:00003924
GAZ:00000587
GAZ:00000560
GAZ:00002525
GAZ:00001103
GAZ:00003744
GAZ:00004525
GAZ:00005282
GAZ:00002637
GAZ:00002931
GAZ:00003756
GAZ:00000554
GAZ:00000559
GAZ:00002464
GAZ:00002471
GAZ:00002471
GAZ:00002846
GAZ:00002467
GAZ:00002466
GAZ:00281547
GAZ:00005860
GAZ:00007550
GAZ:00005852
GAZ:00003936
