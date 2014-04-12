#!/usr/bin/env perl

use strict;
use warnings;

#  input headers: "epitope_id","accession","aliases","synonyms","pubchem_ext_datasource_smiles","pubmed_id"
# output headers: PUBCHEM_EXT_DATASOURCE_REGID,PUBCHEM_SUBSTANCE_SYNONYM,PUBCHEM_EXT_DATASOURCE_URL,PUBCHEM_EXT_SUBSTANCE_URL,PUBCHEM_EXT_DATASOURCE_SMILES,PUBCHEM_PUBMED_ID

my $is_quoted = qr/^"/;
my $match_field_quoted = qr/(.*?)"/;
my $match_field_or_eol = qr/(.*?)(?:,|$)/;
my $intrafield_delim = qr/,\s+/;
&iedb2pubmed($_) for @ARGV;
exit(0);

sub iedb2pubmed {
	my $input_file = shift;
	my $current_epitope_id = -1;
	my @lines = ();
	my %pss = ();
	my $smiles;
	my %pmids = ();
	print "PUBCHEM_EXT_DATASOURCE_REGID,PUBCHEM_SUBSTANCE_SYNONYM,PUBCHEM_EXT_DATASOURCE_URL,PUBCHEM_EXT_SUBSTANCE_URL,PUBCHEM_EXT_DATASOURCE_SMILES,PUBCHEM_PUBMED_ID\r\n";
	open F,$input_file || die "Can't read file $input_file, $!\r\n";
	<F>; ## remove first line, which should be column header names, not data
	while( defined(my $line = <F> ))
	{
		$line =~ s/^\s+//;	
		$line =~ s/\s+$//;
		my $orig_line = $line;
		my($epitope_id,$accession,$aliases,$synonyms,$pubchem_pubmed_id);
		($epitope_id,$line) 	= &take_a_field($line);

		if($current_epitope_id ne $epitope_id) {
			&pubmedify($current_epitope_id,\%pss,$smiles,\%pmids,*STDOUT) if $current_epitope_id != -1;
			$current_epitope_id = $epitope_id;
			%pss = (); %pmids = (); $smiles = undef;
		}

		($accession,$line) 	= &take_a_field($line);
		($aliases,$line) 		= &take_a_field($line);
		($synonyms,$line) 	= &take_a_field($line);
		($smiles,$line) 		= &take_a_field($line);
		($pubchem_pubmed_id,$line) = &take_a_field($line);

		die "Bad line? $orig_line\r\n"
			unless defined $epitope_id && defined $accession && defined $aliases && defined $synonyms && defined $pubchem_pubmed_id && defined $smiles;

#		print "e: $epitope_id\na: $accession\nl: $aliases\ns: $synonyms\np: $pubchem_pubmed_id\n\n\n";

		$pss{$accession} = 1 unless $accession eq '';	
		splitify($aliases,\%pss);
		splitify($synonyms,\%pss);
		$pmids{$pubchem_pubmed_id} = 1 unless $pubchem_pubmed_id eq '';	
	}	
	&pubmedify($current_epitope_id,\%pss,$smiles,\%pmids,*STDOUT);
}

sub splitify {
	my($v,$store) = @_;
	return unless defined $v;
	if($v =~ m/$intrafield_delim/){
		map{$store->{$_}=1 if $_ ne 'null'} (split /$intrafield_delim/,$v);
	}
	elsif ($v ne '' && $v ne 'null'){
		$store->{$v} = 1;
	}
}

sub pubmedify {
	my($epitope_id,$pss,$smiles,$pmids,$outstream) = @_;
	print $outstream join(',',
		"Epitope ID:$epitope_id",
		&mogrify(sort keys %$pss) ,
		"www.iedb.org",
		"http://www.iedb.org/epId/$epitope_id",
		$smiles,
		&mogrify(sort keys %$pmids)
	) . "\r\n";
}

sub mogrify {
	my $retval = join "\x0A", @_; ## also, could try with \n instead of \x0A
	'"' . $retval .'"'
}

sub take_a_field {
	my $str = shift;
	#print "str is $str\n";
	my $field;
	if( $str =~ $is_quoted )
	{
		$str =~ s/$is_quoted//;
		($field)  = $str =~ m/$match_field_quoted/;
		if(defined $field) {
			$str =~ s/$match_field_quoted//;
			$str =~ s/^,//;
		}
		else {
			die "cant take a field from str $str\n";
		}
	} 
	else {
		($field)  = $str =~ m/$match_field_or_eol/;
		$str =~ s/$match_field_or_eol//;
	}
	#print "returning $field, $str\n";
	($field,$str)	
}

