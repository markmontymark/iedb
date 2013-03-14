package IEDB::Results;
use base Listener;

use strict;
use warnings;

our $results = {};

## unused, using second form with addResult,report below. 
## See Also:  Emitter.pm in $opt_listenerSub
sub receive
{
	warn "This Listener doesnt implement the basic Listener interface (only receive is used), \
so you need to pass a Results::coderef when using addEventListener\n";
}


sub addResult
{
	my $this = shift;
	my $data = shift;
	return unless defined $data;
	my $query = $data->{query};
	my $matches = $data->{matches};
	#print "query $query\n";
	$results->{has_multiselect} ++ if $data->{has_multiselect};
	#print "has multiselect? ", (exists $data->{has_multiselect} and $data->{has_multiselect} ? 'y' : 'n') ,"\n";
	for(@$matches)
	{
		unless(ref $_ eq 'ARRAY' && ref $_->[0] eq 'ARRAY')
		{
			&_count_query($_);
			next;
		}
		my $subj_seen = {};
		my $verb_seen = {};
		my $obj_seen = {};
		&_count_query($_,$subj_seen,$verb_seen,$obj_seen) for @$_;
	}
}

sub _count_query
{
	my($q,$subj_seen,$verb_seen,$obj_seen) = @_;
	my $subj = $q->[0];
	my $verb = $q->[1];
	my $obj = scalar(@$q) > 2 ? $q->[2] : undef;
	if(defined $subj_seen && defined $verb_seen && defined $obj_seen)
	{
		unless(exists $subj_seen->{$subj})
		{
			$subj_seen->{$subj} = 1;
			$results->{"subject\t$subj"}++;
			$results->{"multiselect_subject\t$subj"}++;
		}
		unless(exists $verb_seen->{$verb})
		{
			$verb_seen->{$verb} = 1;
			$results->{"verb\t$verb"}++;
			$results->{"multiselect_verb\t$verb"}++;
		}
		if(defined $obj)
		{
			unless(exists $obj_seen->{$obj})
			{
				$obj_seen->{$obj} = 1;
				$results->{"object\t$obj"}++;
				$results->{"multiselect_object\t$obj"}++;
			}
		}
	}
	else
	{
		$results->{"subject\t$subj"}++;
		$results->{"verb\t$verb"}++;
		$results->{"object\t$obj"}++ if defined $obj;
	}
}


sub report
{
	my $this = shift;
	my $opt_fh = shift;
	if(defined $opt_fh)
	{
		print $opt_fh "$_\t$results->{$_}\n" for sort {$results->{$b} <=> $results->{$a} } keys %$results;
	}
	else
	{
		print "$_\t$results->{$_}\n" for sort {$results->{$b} <=> $results->{$a} } keys %$results;
	}
}

 
1;
