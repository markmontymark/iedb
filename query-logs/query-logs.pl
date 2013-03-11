use strict;
use warnings;
use v5.16;
use Text::CSV_XS;


## public methods
##
sub file_to_array;

my $csv_cfg = {
	binary => 1 ,
	sep_char => '|',
	autodie => 1,
};
my $report =  {};
file_to_array $_ for @ARGV;
exit;


sub file_to_array
{
	my($path) = @_;
	#my $csv = Text::CSV_XS->new ({
		#binary => 1 ,
	#}) or die "Cannot use CSV: ".Text::CSV_XS->error_diag ();
	open my $no_op_fh, ">$path.no_op" or die "$path.no_op: $!";
	open my $fh, "<:encoding(utf8)", $path or die "$path: $!";
	<$fh>;
	my $line_i = 1; ## not zero because I just pushed off column header names row in above line, <$fh>;
	##while (my $fields = $csv->getline ($fh)) 
	while (my $line = <$fh>)
	{
	#Log ID|Day of Week|Month|Date|Year|Time|Query|Search Elapsed Time (milliseconds)|Query Completed? (y/n)|List of Incomplete Queries|Number of Users|Number of Other Running Queries|Other Running Queries
	# 0     1           2     3    4    5    6     7                                  8                      9                          10              11
#       12   
		#my @fields = split /[|]/,$line;
		my($f0,$f1,$f2,$f3,$f4,$f5,@f6) = split /[|]/,$line;
		my $query = join '',@f6;
		my $yes_no_idx = 0;
		for(@f6)
		{
			last if /^\s*(?:yes|no)\s*$/;
			$yes_no_idx++;
		}
		if($yes_no_idx == 0)
		{
			say "no yes or no in query $query";
		}
		else
		{
			$query = join '|',(map{$f6[$_]}0..($yes_no_idx-2));
		}
		#say "query $query";
		$line_i++;
		#print "@$row\n";
		#&process_fields($line_i,\@fields,$no_op_fh);
		&process_fields($line_i,$query,$no_op_fh);
	}
	$report->{data_file} = $path;
	$report->{lines} = $line_i;
	&print_report;
	&clear_report;
	#$csv->eof or $csv->error_diag ();
	close $fh;
}



sub process_fields
{
	my($line_i,$fields,$no_op_fh) = @_;
	#Log ID|Day of Week|Month|Date|Year|Time|Query|Search Elapsed Time (milliseconds)|Query Completed? (y/n)|List of Incomplete Queries|Number of Users|Number of Other Running Queries|Other Running Queries
	# 0     1           2     3    4    5    6     7                                  8                      9                          10              11
#       12   
	#my($q,$oq_i,$oq) = ($fields->[6],$fields->[11],$fields->[12]);
	my $q = $fields;
	#$report->{not_13_fields_i}++ if scalar @$fields < 13;
	#print "q: $q, oq_i: $oq_i
	#say "line_i: $line_i, oq_i: $oq_i";
	if(defined $q and $q !~ /^\s*$/)
	{
		$report->{q_defined}++;
		&grok_queries($q,$line_i,$no_op_fh);
	}
	#if(defined $oq_i and $oq_i > 0 and defined $oq and $oq !~ /^\s*$/)
	#{
		#$report->{oq_defined}++;
	#}
}

sub parse_structure_type
{
	my $q = shift;
	return unless $q =~ /structure\s+type\s+equals\s+(Linear peptide|Discontinuous peptide|Non-peptidic)/i;
	$report->{"structure_type-$1"}++;
}


sub grok_queries
{
	my($q,$line_i,$no_op_fh) = @_;
	my @queries = ();
	&parse_structure_type($q);
	if($q =~ /,/)
	{
		#unless($q =~ /['"]/)
		#{
			push @queries,$_ for split /,/,$q;
		#}
		#elsif($q =~ /(['"])[^,\s]*['"]/)
		#{
			#push @queries,$_ for split /,/,$q;
#print "line: $line_i   $q\n";
		#}
		#else
		#{
#print "line: $line_i   $q\n";
			#$report->{"weird csv query"}++;
		#}
	}	
	else
	{
		push @queries,$q;
	}

	my $q_seen = {};
	for(@queries)
	{
		s/^\s+//;
		s/\s+$//;
		my($field,$bucket_name) = $_ =~ m/^\s*(.*?)\s+(is\s+excluded)/i;
		($field,$bucket_name) = $_ =~ m/^\s*(.*?)\s+(blast|is|contains|equals|in|like)\s+/i
			unless defined $field and defined $bucket_name;
		if(defined $field && defined $bucket_name)
		{
			$field =~ s/^\s+//;
			$field =~ s/\s+$//;
			$bucket_name =~ s/^\s+//;
			$bucket_name =~ s/\s+$//;
			if($field =~ /\s+or\s+/i)
			{
				$report->{"has multiselect"}++;
				&grok_multiselects($q,$line_i);
				$field =~ s/^.*\s+or\s+//;
			}
			unless(exists $q_seen->{$field})
			{
				#$report->{"bucket|$bucket_name|$field"}++;
				#$report->{"bucket|$field"}++;
				$q_seen->{$field}++;
			}
		}
		else
		{
			## if no operator found, ignore
			## $report->{"bucket|no_op_match"}++; ## commenting out no_op counts because
			## no_op_match count == no_op_ignore count
			unless(m/^\s+(blast|is\s+excluded|is|contains|equals|in|like)\s+/i)
			{
				#$report->{"bucket|no_op_ignore"}++;
				print $no_op_fh "line $line_i|$_\n";
			}
			#say "no op match line $line_i: $_";
		}
	}
}

sub grok_multiselects
{
	my($q,$line_i) = @_;
	my @subqueries = split /\s+or\s+/,$q;
	my %seen = ();
	for(@subqueries)
	{
		my($subj,$op) = $_ =~ m/^\s*(.*?)\s+(blast|is|contains|equals|in|like)\s+/i;
		unless(defined $subj)
		{
			#say "didnt find subj in line $line_i, $_ from query $q"
			next;
		}
		next if exists $seen{$subj};
		$seen{$subj}=0;
		$report->{"multiselect $subj"}++
	}
}

sub grok_other_queries
{
}

sub clear_report
{
	$report->{$_} = undef for keys %$report;
}

sub print_report
{
	for( sort keys %$report )
	{
		next if /^bucket/i;
		say "$_\t$report->{$_}";
	}
	for( sort {$a =~ /^bucket/ && $b =~ /^bucket/ ? ($report->{$b} <=> $report->{$a}) : -1} keys %$report )
	{
		next unless /^bucket/i;
		(my $n = $_ ) =~ s/^.*?\|//;
		my ($op,$field) = split /[|]/,$n;
		say "$field\t$op\t$report->{$_}";
		#say "$n:$report->{$_}" ;
	}
}
