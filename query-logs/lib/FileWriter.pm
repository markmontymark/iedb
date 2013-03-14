package FileWriter;
use base Listener;

sub init
{
	my $this = shift;
	my %args = @_;
	$this->{fh} = $args{fh} if exists $args{fh} && defined $args{fh};
   $this
}
  
sub receive
{
	my $this = shift;
	my $fh = $this->{fh};
	my $data = shift;
	return unless defined $data;
	chomp $data;
	print $fh $data,"\n";
}
 
1; 
