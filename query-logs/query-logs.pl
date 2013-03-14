#!/usr/bin/env perl

use v5.16;
use lib 'lib';

use strict;
use warnings;

#
#  Emitter interface inspired by 
#	http://perldesignpatterns.com/?EventListeners
#	Mostly made name changes,  broke into separate .pm files and 
#		added support for passing module::coderef instead of just 
#		enforcing module::receive to be the only receiver of an event 
#		for a particular module.  
#		See also query-logs.pl and lib/IEDB/Results.pm for this use.
#

use Emitter;
use Events;
use ReadlineEmitter;
use FileWriter;
use Filenamer;

use IEDB::Events;
use IEDB::QueryLogReadline;
use IEDB::ParseQuery;
use IEDB::Results;

my $emitter = Emitter->new;
my $results = IEDB::Results->new;
$emitter->addListener( $IEDB::Events::RESULTS, $results, \&IEDB::Results::report);

my $queries_file = &Filenamer::condense_argv;
open my $queries_fh, ">$queries_file.queries" or die "Can't create $queries_file.queries, $!\n";
my $query_log = FileWriter->new(fh=>$queries_fh) ;

for(@ARGV)
{
	open my $fh, "<$_" or die "Can't read $_, $!\n";
	<$fh>; # read past first line, which is a line of column names, not data
	my $emitter = ReadlineEmitter->new($fh);
	$emitter->addListener( $Events::READLINE, IEDB::QueryLogReadline->new );
	$emitter->addListener( $IEDB::Events::LOGQUERY, $query_log );
	$emitter->addListener( $IEDB::Events::PARSEQUERY, IEDB::ParseQuery->new );
	$emitter->addListener( $IEDB::Events::ADDRESULT, $results, \&IEDB::Results::addResult );
	$emitter->start;
}

open my $results_fh, ">$queries_file.results" or die "Can't create $queries_file.results, $!\n";
$emitter->emit( $IEDB::Events::RESULTS,$results_fh );

