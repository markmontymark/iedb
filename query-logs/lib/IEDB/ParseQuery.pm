package IEDB::ParseQuery;
use base Listener;

use strict;
use warnings;

use IEDB::Events;

our $qr_subj_verb = qr/^\s*([^,]+)\s+(is\s+excluded)\s*$/;
our $qr_subj_verb_obj = qr/^\s*([^,]+)\s+(equals|contains|is|blast)\s+([^,]+)\s*$/;
our $qr_or_delimiter = qr/\s+or\s+/;

sub receive
{
	my $this = shift;
	my $query = shift;
	return unless defined $query;

	my $matches = [];
	my $has_multiselect = 0;

	## getting complex, we have multi-select queries, so that's multiple [subject|verb|[object]]+ separated by , or 'or'
	unless( &_find_subquery($query,$matches) )
	{
		# split on ',' first, 'or' second and see if any subqueries fail a  subj|verb|(obj)* match
		for( split /,/,$query)
		{
			if( $_ =~ $qr_or_delimiter )
			{
				my $submatches = [];
				&_find_subquery($_,$submatches) for split $qr_or_delimiter,$_;
				if(scalar(@$submatches) > 0)
				{
					$has_multiselect = 1 unless $has_multiselect;
					push @$matches,$submatches 
				}
			}
			else
			{
				&_find_subquery($_,$matches);
			}
		}
	}
	$this->emitter->emit( 
		$IEDB::Events::ADDRESULT, 
		{ query => $query, matches =>$matches, has_multiselect => $has_multiselect }
	);
}


sub _find_subquery
{
	my($query,$matches) = @_;
	my @subquery_matches;

   ## simple match, subject verb
	if(@subquery_matches = $query =~ m/$qr_subj_verb/)
   {
      #print "subj verb matches: @matches from $query\n";
      push @$matches,[@subquery_matches];
		return 1;
   }
   ## simple match, subject verb object
   elsif( $query !~ $qr_or_delimiter and (@subquery_matches = $query =~ m/$qr_subj_verb_obj/))
   {
      push @$matches,[@subquery_matches];
		return 1;
   }
}
 
1; 
