package Emitter;
  
sub new 
{
	my $class = shift;
	my $this = {events=>{}};
	bless $this, $class
}
  
sub addListener 
{
	my $this = shift;
	my $name = shift; 
	my $listener = shift; 
	my $opt_listenerSub = shift; 
	$listener->isa('Listener') or die "You called $this -> addListener with an non-Listener argument\n";
	$listener->setEmitter($this) unless $listener->hasEmitter;
	## TODO should be a push for multiple listeners of an event $this->{events}->{$name} = $listener;
	$this->{events}->{$name} = defined $opt_listenerSub ? [$listener,$opt_listenerSub] : $listener;
	$this
}
  
sub removeListener 
{
	my $this = shift;
	my $listener = shift; 
	$listener->isa('Listener') or die;
	## TODO should be a pop of $this to handle multiple listeners of an event $this->{events}->{$name} = $listener;
	delete $this->{events}->{$listener};
	$this
}
  
sub emit
{
	my $this = shift;
	my $name = shift;
	return unless $name;
	my $listener = $this->{events}->{$name};
	return unless defined $listener;
	my $data = shift;
#	print "broadcastEvent this $this, en $name, er $listener, ed $data\n";
	## TODO should be a for here, to loop over all handlers of an name (so listener should be an array ref)
	eval
	{ 
		#print "receiver $listener name $name data $event_data\n";
		#$listener->receive($name,$data);
		if(ref $listener eq 'ARRAY') ## see $opt_listenerSub above
		{
#			print "broadcast second form\n";
			$listener->[1]->($listener->[0],$data);
		}
		else
		{
			$listener->receive($data);
		}
	};
	warn $@ if $@;
}
 
1; 
