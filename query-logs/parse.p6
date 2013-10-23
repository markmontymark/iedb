#!/usr/bin/env perl6

grammar QueryGrammar {
	rule TOP       { ^ <query>+? % "," $  }
	rule query    { <subquery>+ % "or" }
	rule subquery { <words> }
	token words   { <word>+ % <.ws> }
	token word    { <-[,\s]>+ }  ## words are anything without a space or comma
}

class QueryActions {

	has %.results;

	method word ($/) { 
		make ~$/
	}

	method words($/) { 
		my @words = $/.caps>>.value>>.ast;
		self.orify: @words;
	}
	method orify( @list ) {
		my @tmp;
		my $subject;
		for @list -> $w {
			if $w eq 'is' {
				$subject = join ' ',@tmp;	
				@tmp = ();
			}
			elsif defined $subject {
				if $w eq 'or'  {
					add-result( $subject , join ' ',@tmp );
					@tmp = ();
					$subject = Nil;
				}
				else {
					@tmp.push: $w;
				}
			}
			else {
				@tmp.push: $w;
			}
		}
		
		add-result( $subject , join ' ',@tmp )
			if @tmp > 0 && defined $subject;
	}
}


my %results;
sub add-result( $subj,$obj ) {
	%results{ $subj }{ $obj }++;
}

sub process-file( Str $filename ) {
	say "got filename $filename";
	my $fh = open $filename, :r;	
	my $actions = QueryActions.new();
	for $fh.lines -> $line {
		QueryGrammar.parse($line, :$actions);
	}
	say %results;
}

sub MAIN( *@files ) {

	process-file($_) for @files;

		#"B Cell is excluded or T Cell is excluded or Source Organism is HLA-A*03:01",
	#"B Cell is excluded or T Cell is excluded or Source Organism is HLA-A*03:01",
		##"Source Organism is HLA-A*03:01",
		#"Source Organism is HLA-A*03:01, B Cell is BLB-B*99:99",
		#"BCell is excluded",
		#"B Cell is excluded",
		#"TCell is excluded or BCell is excluded",
		#"T Cell is excluded or B Cell is excluded",
		#"BCell is excluded,TCell is excluded",
		#"BCell is excluded, TCell is excluded",
		#"B Cell is excluded , T Cell is excluded",
		#"B Cell is excluded,T Cell is excluded",
		#"B Cell is excluded,T Cell is excluded or B Cell is excluded",
		#"T Cell is excluded or B Cell is excluded",
		#"Source is Mycobacterium",
		#"Source Organism is Mycobacterium tuberculosis",
		#"Source Organism is Mycobacterium tuberculosis or Source Organism is Mycobacterium tuberculosis H37Rv",
		#"Source Organism is Mycobacterium tuberculosis or Source Organism is Mycobacterium tuberculosis H37Rv, B Cell is excluded, Host Organism is Homo sapiens(human), MHC Restriction is HLA-A*02:05 or MHC Restriction is HLA-A*03:01 or MHC Restriction is HLA-A*23:01 or MHC Restriction is HLA-A*30:02 or MHC Restriction is HLA-B*08:01 or MHC Restriction is HLA-B*15:03 or MHC Restriction is HLA-B*42:01"
	#) 
	#{
	#}


}

