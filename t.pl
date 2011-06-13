#!/usr/bin/perl 
#===============================================================================
#
#         FILE:  t.pl
#
#        USAGE:  ./t.pl  
#
#  DESCRIPTION:  
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  YOUR NAME (), 
#      VERSION:  1.0
#      CREATED:  06/10/2011 02:36:35 PM
#===============================================================================

BEGIN{
	push @INC, ".";
}

use strict;
use warnings;

use Moose;
use ODataTypes;

use XML::Atom;
use Atompub::Client;
use Data::Printer;

my $m = 'http://schemas.microsoft.com/ado/2007/08/dataservices/metadata';

sub build_meta_class {
	my $namespace = shift;
	my $entry = shift;

	my $metaclass = Moose::Meta::Class->create($namespace);

	my $content = $entry->content;
	my @properties = grep { ref $_ eq 'XML::LibXML::Element' } $content->elem->childNodes();
	foreach my $property ( @properties ) {
		my @elem = grep { ref $_ eq 'XML::LibXML::Element' } $property->childNodes();
		foreach my $elem ( @elem ) {
			my $type = $elem->getAttributeNS($m, 'type');
			$metaclass->add_attribute(
				$elem->localname(), {
					is     => 'rw',
					isa    => $type,
					coerce => $ODataTypes::coerce_map{$type},
					}
				)
			}
		}
	return $metaclass;
	}

my $d_ns = XML::Atom::Namespace->new('d' => 'http://schemas.microsoft.com/ado/2007/08/dataservices');
my $m_ns = XML::Atom::Namespace->new('m' => 'http://schemas.microsoft.com/ado/2007/08/dataservices/metadata');


my $service_url = 'http://services.odata.org/OData/OData.svc';

my $namespace = "OData::Products";

my $client = Atompub::Client->new;

my $service = $client->getService($service_url) or die "Couldn't get a document from $service_url\n";
 
my @workspaces = $service->workspaces;
my @collections = $workspaces[0]->collections;

my $collection_uri = $service_url . "/" . $collections[0]->href;

my $feed = $client->getFeed($collection_uri);
my @entries = $feed->entries;

#p @entries;

my $factory = build_meta_class($namespace, $entries[0]);

my @rv;

foreach my $entry ( @entries ) {
	my $hr;
	my $content = $entry->content;
	my @properties = grep { ref $_ eq 'XML::LibXML::Element' } $content->elem->childNodes();
	foreach my $property ( @properties ) {
		my @elem = grep { ref $_ eq 'XML::LibXML::Element' } $property->childNodes();
		foreach my $elem ( @elem ) {
			my $n = $elem->localname();
			$hr->{ $n } = $elem->getAttributeNS($m, 'null') ? undef : $elem->textContent();
			}
		}
	#p $hr;
	push @rv, $factory->new_object($hr);
	}

p @rv;
