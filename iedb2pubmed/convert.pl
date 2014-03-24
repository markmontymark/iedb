#!/usr/bin/env perl

use strict;
use warnings;

#  input headers: "epitope_id","accession","aliases","synonyms","pubmed_id"
# output headers: PUBCHEM_EXT_DATASOURCE_REGID,PUBCHEM_SUBSTANCE_SYNONYM,PUBCHEM_EXT_DATASOURCE_URL,PUBCHEM_EXT_SUBSTANCE_URL,PUBCHEM_PUBMED_ID

&iedb2pubmed($_) for @ARGV;
exit(0);

sub iedb2pubmed {
	my $if = shift;
	(my $of = "$if") =~ s/\.csv$/-out.csv/;
	my $current_epitope_id = -1;
	my @lines = ();
	my %pss = ();
	my %pmids = ();
	print "PUBCHEM_EXT_DATASOURCE_REGID,PUBCHEM_SUBSTANCE_SYNONYM,PUBCHEM_EXT_DATASOURCE_URL,PUBCHEM_EXT_SUBSTANCE_URL,PUBCHEM_PUBMED_ID\n";
	open F,"$if" || die "Can't read file $if, $!\n";
	<F>; ## remove first line
	while( defined(my $line = <F> ))
	{
		$line =~ s/^\s+//;	
		$line =~ s/\s+$//;
		my $orig_line = $line;
		my($epitope_id,$accession,$aliases,$synonyms,$pubmed_id);
		($epitope_id,$line) = &take_a_field($line);
		($accession,$line) = &take_a_field($line);
		($aliases,$line) = &take_a_field($line);
		($synonyms,$line) = &take_a_field($line);
		($pubmed_id,$line) = &take_a_field($line);
		die "Bad line? $orig_line\n"
			unless defined $epitope_id && defined $accession && defined $aliases && defined $synonyms && defined $pubmed_id;

#		print "e: $epitope_id\na: $accession\nl: $aliases\ns: $synonyms\np: $pubmed_id\n\n\n";

		if($current_epitope_id ne $epitope_id) {
			&pubmedify($current_epitope_id,\%pss,\%pmids,*STDOUT) if $current_epitope_id != -1;
			%pss = ();
			%pmids = ();
			$current_epitope_id = $epitope_id;
		}
		$pss{$accession} = 1 if $accession ne '';	
		splitify($aliases,\%pss);
		splitify($synonyms,\%pss);
		$pmids{$pubmed_id} = 1 if $pubmed_id ne '';	
	}	
	&pubmedify($current_epitope_id,\%pss,\%pmids,*STDOUT);
}

sub splitify {
	my($v,$store) = @_;
	if($v =~ m/, /){
		for(split ', ',$v){
			$store->{$_} = 1 if $_ ne '';
		}
	}
	elsif ($v ne ''){
		$store->{$v} = 1;
	}
}

sub pubmedify {
	my($epitope_id,$pss,$pmids,$outstream) = @_;
	print $outstream join(',',
		"Epitope ID:$epitope_id",
		&mogrify(keys %$pss) ,
		"www.iedb.org",
		"http://www.iedb.org/epId/$epitope_id",
		&mogrify(keys %$pmids)
	) . "\r\n";
}

sub mogrify {
	my $retval = join "\x0A", @_;
	'"' . $retval .'"'
}

sub take_a_field {
	my $str = shift;
	#print "str is $str\n";
	my $field;
	if(index($str, '"') == 0)
	{
		$str = substr $str,1;
		($field)  = $str =~ m/(.*?)"/;
		if(defined $field) {
			$str =~ s/.*?"//;
			$str =~ s/^,//;
		}
		else {
			die "cant take a field from str $str\n";
		}
	} 
	else {
		($field)  = $str =~ m/(.*?)(?:,|$)/;
		$str =~ s/.*?,//;
	}
	#print "returning $field, $str\n";
	($field,$str)	
}

__DATA__

# IEDB Data Store.csv
"epitope_id","accession","aliases","synonyms","pubmed_id"
110163,"CHEBI:34718","DNCB, 2,4-dinitrochlorobenzene","1,3-Dinitro-4-chlorobenzene, 1-Chloro-2,4-dinitrobenzene, 1-Chloro-2,4-dinitrobenzol, 2,4-Dinitro-1-chlorobenzene, 2,4-Dinitrochlorobenzene, 2,4-Dinitrophenyl chloride, 4-Chloro-1,3-dinitrobenzene, 6-Chloro-1,3-dinitrobenzene, Cdnb, Chlorodinitrobenzene, ClDNB, Dinitrochlorobenzene, DNCB, Dncb, DNPCl","18316151"
110163,"CHEBI:34718","DNCB, 2,4-dinitrochlorobenzene","1,3-Dinitro-4-chlorobenzene, 1-Chloro-2,4-dinitrobenzene, 1-Chloro-2,4-dinitrobenzol, 2,4-Dinitro-1-chlorobenzene, 2,4-Dinitrochlorobenzene, 2,4-Dinitrophenyl chloride, 4-Chloro-1,3-dinitrobenzene, 6-Chloro-1,3-dinitrobenzene, Cdnb, Chlorodinitrobenzene, ClDNB, Dinitrochlorobenzene, DNCB, Dncb, DNPCl","22069292"
110163,"CHEBI:34718","DNCB, 2,4-dinitrochlorobenzene","1,3-Dinitro-4-chlorobenzene, 1-Chloro-2,4-dinitrobenzene, 1-Chloro-2,4-dinitrobenzol, 2,4-Dinitro-1-chlorobenzene, 2,4-Dinitrochlorobenzene, 2,4-Dinitrophenyl chloride, 4-Chloro-1,3-dinitrobenzene, 6-Chloro-1,3-dinitrobenzene, Cdnb, Chlorodinitrobenzene, ClDNB, Dinitrochlorobenzene, DNCB, Dncb, DNPCl","21404309"
112424,"CHEBI:42017","","1-hydroxy-2,4-dinitrobenzene, 2,4-Dinitrophenol, 2,4-DINITROPHENOL, 2,4-DNP, alpha-dinitrophenol","7084424"
112424,"CHEBI:42017","","1-hydroxy-2,4-dinitrobenzene, 2,4-Dinitrophenol, 2,4-DINITROPHENOL, 2,4-DNP, alpha-dinitrophenol","7199878"
112424,"CHEBI:42017","","1-hydroxy-2,4-dinitrobenzene, 2,4-Dinitrophenol, 2,4-DINITROPHENOL, 2,4-DNP, alpha-dinitrophenol","6196609"
112424,"CHEBI:42017","","1-hydroxy-2,4-dinitrobenzene, 2,4-Dinitrophenol, 2,4-DINITROPHENOL, 2,4-DNP, alpha-dinitrophenol","7252420"
112424,"CHEBI:42017","","1-hydroxy-2,4-dinitrobenzene, 2,4-Dinitrophenol, 2,4-DINITROPHENOL, 2,4-DNP, alpha-dinitrophenol","1087316"
112424,"CHEBI:42017","","1-hydroxy-2,4-dinitrobenzene, 2,4-Dinitrophenol, 2,4-DINITROPHENOL, 2,4-DNP, alpha-dinitrophenol","7393370"
112424,"CHEBI:42017","","1-hydroxy-2,4-dinitrobenzene, 2,4-Dinitrophenol, 2,4-DINITROPHENOL, 2,4-DNP, alpha-dinitrophenol","657786"
112424,"CHEBI:42017","","1-hydroxy-2,4-dinitrobenzene, 2,4-Dinitrophenol, 2,4-DINITROPHENOL, 2,4-DNP, alpha-dinitrophenol","6653106"
112424,"CHEBI:42017","","1-hydroxy-2,4-dinitrobenzene, 2,4-Dinitrophenol, 2,4-DINITROPHENOL, 2,4-DNP, alpha-dinitrophenol","1155304"
112424,"CHEBI:42017","","1-hydroxy-2,4-dinitrobenzene, 2,4-Dinitrophenol, 2,4-DINITROPHENOL, 2,4-DNP, alpha-dinitrophenol","1032127"
112424,"CHEBI:42017","","1-hydroxy-2,4-dinitrobenzene, 2,4-Dinitrophenol, 2,4-DINITROPHENOL, 2,4-DNP, alpha-dinitrophenol","6193174"
112424,"CHEBI:42017","","1-hydroxy-2,4-dinitrobenzene, 2,4-Dinitrophenol, 2,4-DINITROPHENOL, 2,4-DNP, alpha-dinitrophenol","342294"
112424,"CHEBI:42017","","1-hydroxy-2,4-dinitrobenzene, 2,4-Dinitrophenol, 2,4-DINITROPHENOL, 2,4-DNP, alpha-dinitrophenol","8000708"
112424,"CHEBI:42017","","1-hydroxy-2,4-dinitrobenzene, 2,4-Dinitrophenol, 2,4-DINITROPHENOL, 2,4-DNP, alpha-dinitrophenol","12324415"

# liai-example.csv

0                            1                         2                          3                         4
PUBCHEM_EXT_DATASOURCE_REGID,PUBCHEM_SUBSTANCE_SYNONYM,PUBCHEM_EXT_DATASOURCE_URL,PUBCHEM_EXT_SUBSTANCE_URL,PUBCHEM_PUBMED_ID
Epitope ID:112424,"CHEBI:42017
1-hydroxy-2,4-dinitrobenzene
2,4-Dinitrophenol
2,4-DINITROPHENOL
2,4-DNP
alpha-dinitrophenol
DNP",www.iedb.org,http://www.iedb.org/epId/112424,"23050868
20096324
15307184
12324415
11680568
10727322
8000708
1640019
1868701
1917113
2522294
3180787
3329913
6653106
6196609
6193174
7199878
7084424
6215337
7252420
7213549
7393370
657786
342294
301552
1087316
1032127
1155304
4403230
4109111"
