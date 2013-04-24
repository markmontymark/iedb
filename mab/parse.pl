
use strict;
use warnings;

=head1 Prerequisites

Text::CSV_XS

=cut

use Text::CSV_XS;

=head1 Usage 

perl parse.pl file1 [file2 ... fileN]

=cut
my($file) = @ARGV;
my $col_to_find = 'ab_name';
my $csv_opts = { binary => 1, eol => $/ };
my $test = 0;

for my $file(@ARGV)
{
	&test_count_fields_per_line($file) if $test;
	&dupe_line_per_multivalue_cell($file);
}
exit;

=head1 Duplicate lines with multiple values

The purpose of thie script is to transform a CSV file with the format:

	(row i) a,b,c,"1,2,3"

becomes

	(row i) a,b,c,1
	(row i+1) a,b,c,2
	(row i+2) a,b,c,3

=cut
sub dupe_line_per_multivalue_cell
{
	my($file) = @_;
	(my $outfile = $file) =~ s/before/after/;
	my $csv = Text::CSV_XS->new($csv_opts);
	open my $of, ">", $outfile or die "$outfile: $!";
	open my $io, "<", $file or die "$file: $!";
	my $row = $csv->getline ($io); ## first line is a column header names line
	$csv->print($of,$row);
	my $idx = -1;
	for(@$row)
	{
		$idx++;
		#print "$i   $_\n" if /^\s*ab_name\s*$/i;
		last if /^\s*$col_to_find\s*$/i;
	}
	die "Didn't find $col_to_find column\n" if $idx == -1 or $idx == (scalar(@$row) - 1);

	my $n_multivalue_found = 0;
	my $line_count = 0;
	while ($row = $csv->getline ($io)) 
	{
		my $field = $row->[$idx];
		if(index($field,',') > -1)
		{
			$n_multivalue_found++;
			#print "$field\n";
			for( split ',',$field )
			{
				if( /and/ )
				{
					#print "$_\n";
					for( split 'and' )
					{
						s/^\s+//;
						s/\s+$//;
						next unless $_;
						$row->[$idx] = $_;
						$csv->print($of,$row);
					}
				}
				else
				{
					$row->[$idx] = $_;
					$csv->print($of,$row);
				}
			}
		}
		elsif($field =~ /\sand\s/)
		{
			#$csv->print($of,$row);
			print "found and with no commas, $field\n";
			for( split /\sand\s/,$field )
			{
				s/^\s+//;
				s/\s+$//;
				next unless $_;
				print "\t$_\n";
				$row->[$idx] = $_;
				$csv->print($of,$row);
			}
		}
		else
		{
			$csv->print($of,$row);
		}
	}
	print "found $n_multivalue_found with multivalues\n" if $n_multivalue_found > 0;
	close $io;
}


=head1 Test field count per line

A test subroutine for checking that all lines, when parsed by Text::CSV_XS (with the options as set)
all have the same number of fields per line.  If some lines have a different amount of fields, then
the parsing may not be correct and you'll have to dig into changing Text::CSV_XS options, or 
dig into the file as see what's up.

Enable/disable running this test sub by setting $test to true or false at top of script.

=cut
sub test_count_fields_per_line
{
	my($file) = @_;
	my $csv = Text::CSV_XS->new($csv_opts);
	open my $io, "<", $file or die "$file: $!";
	my %n_fields;
	while (my $row = $csv->getline ($io)) 
	{
		my @fields = @$row;
		$n_fields{ scalar @fields }++;
	}
	close $io;
	print "n fields $_  found in $n_fields{$_} lines\n" for sort keys %n_fields;
	die "Error: found at least one line with a differing field count.\n" if scalar(keys %n_fields) > 1;
}
