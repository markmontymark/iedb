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
open K,">$ARGV[0].round4" || die "Can't open $ARGV[0].round4, $!\n";
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
say "n terms we care about but didn't find:\n";
for(keys %kids)
{
	print "$_\n" if $kids{$_} == 0;
}

sub collectTerm
{
	my($lines) = @_;
	my $id;
	for(@$lines)
	{
		## id:GAZ:00000465
		if(/^\s*id\s*:\s*(GAZ\:\d+)\s*$/i)
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
GAZ:00006882
GAZ:00000457
GAZ:00002953
GAZ:00000563
GAZ:00002948
GAZ:00002948
GAZ:00001095
GAZ:00000462
GAZ:00002467
GAZ:00002928
GAZ:00004094
GAZ:00000465
GAZ:00005863
GAZ:00000463
GAZ:00002942
GAZ:00004941
GAZ:00005281
GAZ:00003734
GAZ:00006886
GAZ:00002938
GAZ:00002934
GAZ:00000904
GAZ:00002511
GAZ:00006887
GAZ:00001097
GAZ:00002828
GAZ:00281547
GAZ:00003901
GAZ:00002950
GAZ:00000905
GAZ:00001090
GAZ:00006888
GAZ:00001093
GAZ:00002560
GAZ:00002469
GAZ:00000588
GAZ:00001089
GAZ:00002891
GAZ:00002463
GAZ:00000586
GAZ:00002825
GAZ:00002845
GAZ:00002929
GAZ:00003937
GAZ:00002901
GAZ:00000906
GAZ:00002719
GAZ:00002954
GAZ:00001086
GAZ:00000582
GAZ:00000556
GAZ:00002471
GAZ:00002912
GAZ:00003934
GAZ:00000561
GAZ:00000855
GAZ:00002935
GAZ:00002641
GAZ:00001091
GAZ:00000581
GAZ:00002959
GAZ:00000567
GAZ:00000460
GAZ:00000464
GAZ:00002937
GAZ:00067144
GAZ:00002940
GAZ:00001092
GAZ:00000907
GAZ:00004942
GAZ:00002646
GAZ:00000908
GAZ:00004790
GAZ:00002945
GAZ:00002936
GAZ:00000909
GAZ:00000910
GAZ:00002522
GAZ:00002894
GAZ:00002952
GAZ:00002949
GAZ:00002949
GAZ:00002839
GAZ:00000466
GAZ:00003727
GAZ:00004474
GAZ:00004483
GAZ:00007550
GAZ:00002476
GAZ:00003101
GAZ:00002650
GAZ:00002747
GAZ:00024383
GAZ:00002473
GAZ:00004999
GAZ:00001101
GAZ:00000591
GAZ:00002800
GAZ:00011337
GAZ:00005285
GAZ:00006893
GAZ:00006889
GAZ:00002958
GAZ:00002478
GAZ:00001098
GAZ:00002466
GAZ:00000911
GAZ:00000566
GAZ:00003858
GAZ:00002960
GAZ:00002947
GAZ:00006895
GAZ:00001108
GAZ:00001105
GAZ:00003902
GAZ:00000584
GAZ:00000583
GAZ:00005860
GAZ:00005852
GAZ:00003940
GAZ:00005851
GAZ:00004126
GAZ:00003936
GAZ:00002852
GAZ:00003897
GAZ:00003857
GAZ:00008744
GAZ:00006898
GAZ:00000565
GAZ:00001100
GAZ:00006899
GAZ:00058174
GAZ:00001096
GAZ:00004399
GAZ:00002978
GAZ:00000585
GAZ:00000912
GAZ:00000555
GAZ:00000458
GAZ:00002801
GAZ:00002846
GAZ:00002638
GAZ:00005283
GAZ:00005246
GAZ:00002475
GAZ:00002892
GAZ:00003922
GAZ:00002933
GAZ:00002932
GAZ:00002939
GAZ:00005861
GAZ:00003944
GAZ:00001088
GAZ:00002943
GAZ:00001094
GAZ:00002951
GAZ:00002721
GAZ:00001087
GAZ:00005279
GAZ:00003606
GAZ:00002639
GAZ:00000913
GAZ:00002957
GAZ:00000914
GAZ:00003923
GAZ:00002956
GAZ:00002955
GAZ:00001104
GAZ:00000553
GAZ:00000459
GAZ:00002472
GAZ:00004940
GAZ:00002802
GAZ:00000559
GAZ:00002464
GAZ:00003924
GAZ:00000587
GAZ:00000560
GAZ:00002525
GAZ:00001099
GAZ:00002729
GAZ:00002941
GAZ:00002474
GAZ:00006912
GAZ:00001103
GAZ:00003744
GAZ:00002946
GAZ:00004525
GAZ:00006913
GAZ:00000915
GAZ:00000562
GAZ:00000558
GAZ:00005018
GAZ:00001102
GAZ:00002724
GAZ:00005282
GAZ:00002637
GAZ:00002930
GAZ:00004979
GAZ:00002931
GAZ:00003756
GAZ:00002640
GAZ:00000554
GAZ:00005284
GAZ:00001107
GAZ:00001106
