package ReadlineEmitter;
use base qw/Emitter/;
 
use Events;
 
sub new 
{
	my $class = shift;
	my $this = $class->SUPER::new(@_);
   my $filehandle = shift;
   $this->{fileHandle} = $filehandle;
	$this
}
  
sub start 
{
	my $this = shift;
	my $filehandle = $this->{fileHandle};
	$this->emit($Events::READLINE,$_) while <$filehandle>;
}
 
1; 
