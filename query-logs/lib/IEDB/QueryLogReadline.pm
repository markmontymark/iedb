package IEDB::QueryLogReadline; 
use base Listener;

use strict;
use warnings;

use IEDB::Events;

sub receive
{
	my $this = shift;
	my $data = shift;
	return unless defined $data;
	chomp $data;
	my($f0,$f1,$f2,$f3,$f4,$f5,@f6) = split /[|]/,$data;
	my $query = join '',@f6;

	## deal with query having | chars in it, ie entire field isn't quoted if it contains the delimiter character
	my $yes_no_idx = 0;
	for(@f6)
	{
		last if /^\s*(?:yes|no)\s*$/;
		$yes_no_idx++;
	}

	$query = join '|',(map{$f6[$_]}0..($yes_no_idx-2)) if $yes_no_idx != 0;
	return if $query =~  /^\s*$/;

	$query =~ s/^\s+//;
	$query =~ s/\s+$//;

	$this->emitter->emit( $IEDB::Events::LOGQUERY,	$query );
	$this->emitter->emit( $IEDB::Events::PARSEQUERY,$query );
}
 
1; 
