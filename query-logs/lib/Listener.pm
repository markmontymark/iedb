package Listener;

sub new 
{
	my $class = shift;
	my $this = bless {},$class;
	$this->init(@_) if $this->can( 'init' );
	$this
}
  
sub hasEmitter
{
	my $this = shift;
	defined $this and exists $this->{emitter}
}

sub setEmitter
{
	my $this = shift;
	my $emitter = shift;
	$this->{emitter} = $emitter;
}

sub emitter
{
	shift->{emitter}
}

sub receive
{
    warn "Listener::receive not overriden to do anything useful";
}

1;
  
