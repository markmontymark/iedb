package Filenamer;

use strict;
use warnings;

#
#  Tries to takes @ARGV and condense it into a shortish string
#  Example:  ./myscript.pl file1.txt file2.txt file3.txt would be condensed to
#	file1__2__3.txt
#	
sub condense_argv
{
	my $args = [@ARGV];
	my @fn = (shift @$args);
	return $fn[0] unless scalar @$args;
	my @first_letters = split '',$fn[0];
	my $first_letters_len = scalar @first_letters;
	my($first_ext) = $fn[0] =~ m/(\.[^\.]+)$/;
	my $qr_first_ext = defined $first_ext ? qr/$first_ext/ : undef;
	$fn[0] =~ s/$first_ext//g if defined $first_ext;
	my %qs;
	for my $arg (@$args)
	{	
		my $idx = 0;
		my $i = 0;
		for(split //,$arg)
		{
			if($i < $first_letters_len)
			{
				if( $first_letters[$i] ne $_)
				{
					$idx  = $i;
					last;
				}
				$i++;
			}
		}
		$arg = substr $arg,$idx if $idx > 0;
		$arg =~ s/$first_ext$// if defined $qr_first_ext and $arg =~ $qr_first_ext;
		push @fn,$arg;
	}
	my $final_fn = join('__',@fn); ## no file extension on return value . $first_ext;
	$final_fn =~ s/[^0-9A-Za-z\.\,\-\_]/--/g;
	$final_fn
}

1;
