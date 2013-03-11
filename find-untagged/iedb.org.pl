
use strict;
use warnings;
use v5.16;

use WWW::Mechanize;

(my $base_url= "http://$0/") =~ s/\.[^\.]+$//;
(my $links_file = "$0.links.txt") =~ s/\.pl//;
my $ga = qr/UA-21275858-1/;
say "Search $base_url for $ga";
my %_seen;
my %all_links;
&read_links;
$all_links{$base_url} = 0 unless scalar keys %all_links;
my $ua = WWW::Mechanize->new();
&find_untagged($ua,$_,$ga) for keys %all_links;
&store_links;

exit;

sub find_untagged
{
	my($ua,$url,$match_qr) = @_;
	return if &has_seen($url);
	$ua->get( $url );
	&seen($url, $ua->content =~ $match_qr ? 1 : -1);
	my @links = $ua->links;
	my $current_uri = $ua->uri;
	&add_links($current_uri,\@links);
}

sub has_seen
{
	my $url = shift;
	exists $_seen{$url}
}

sub seen
{
	my($url,$state) = @_;
	say "seen $url state $state";
	$_seen{$url} = $state;
}

sub add_links
{
	my($current_uri,$links) = @_;
	for(@$links)
	{
		my $link_url = $_->url;
		next if index($link_url , '#') == 0;
		next if $link_url =~ /\.css$/;
		next if $link_url =~ /^[a-z]+:\/\//;
		#$link_url =~ s/^\/// if $base_url !~ /\/$/;
		$base_url .= '/' unless $base_url =~ /\/$/;
		$link_url = "$base_url/$link_url";
		next if exists $all_links{$link_url};
		$all_links{$link_url} = 0;
	}
}

sub store_links
{
	open F,">$links_file" or die "Can't write $links_file, $!\n";
	print F "$_\t$all_links{$_}\n" for sort keys %all_links;
	close F;
}

sub read_links
{	
	return {} unless -e $links_file;
	open F,$links_file or die "Can't read $links_file, $!\n";
	while(<F>)
	{
		chomp;
		my($url,$checked) = split "\t";
		$all_links{$url} = $checked;
	}
}
