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
use DateTime::Tiny;

my $m = 'http://schemas.microsoft.com/ado/2007/08/dataservices/metadata';

sub build_content_meta_class {
	my $namespace = shift;
	my $entry = shift;

	$namespace .= "::Content";

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

my $namespace_stem = "ODataDemo";

my $client = Atompub::Client->new;

my $service = $client->getService($service_url) or die "Couldn't get a document from $service_url\n";
 
my @workspaces = $service->workspaces;
my @collections = $workspaces[0]->collections;

my $collection_uri = $service_url . "/" . $collections[0]->href;

my $collection_namespace = $namespace_stem . "::" . $collections[0]->title;

my $feed = $client->getFeed($collection_uri);

my $collection_factory = Moose::Meta::Class->create($collection_namespace . "::Collection");

my $entry_namespace = $collection_namespace . "::Entry";

$collection_factory->add_attribute('entries', {
	traits  => ['Array'],
	is      => 'rw',
	isa     => "ArrayRef[$entry_namespace]",
	default => sub { [] },
	handles => {
		add_entry => 'push',
		iter => 'shift',
		},
	}
	);

my $collection = $collection_factory->new_object();
	
my @entries = $feed->entries;

my $entry_factory = Moose::Meta::Class->create($entry_namespace);

$entry_factory->add_attribute('id', {
	is     => 'rw',
	isa    => 'Str',
	}
	);

$entry_factory->add_attribute('title', {
	is     => 'rw',
	isa    => 'Str',
	}
	);

$entry_factory->add_attribute('summary', {
	is     => 'rw',
	isa    => 'Str',
	}
	);

$entry_factory->add_attribute('updated', {
	is     => 'rw',
	isa    => 'DateTime::Tiny',
	}
	);

$entry_factory->add_attribute('author', {
	is     => 'rw',
	isa    => 'XML::Atom::Person',
	} 
	);

$entry_factory->add_attribute('links', {
	traits => ['Hash'],
    is     => 'rw',
	isa    => 'HashRef[Str]',
	default => sub { {} },
	handles => {
		set_link => 'set',
		each_link => 'kv',
		},
	}
	);

my $content_namespace = $entry_namespace . "::Content";

$entry_factory->add_attribute('content', {
	is     => 'rw',
	isa    => "$content_namespace",
	}
	);

my $content_factory = build_content_meta_class($entry_namespace, $entries[0]); 

foreach my $entry ( @entries ) {
	my $entry_obj = $entry_factory->new_object();
    $entry_obj->id($entry->id);	
    $entry_obj->title($entry->title);	
	$entry_obj->summary($entry->summary);
	my $dt = $entry->updated;
	chop($dt);
	$entry_obj->updated(DateTime::Tiny->from_string($dt));
	$entry_obj->author($entry->author);
	
	foreach my $link ( $entry->link ) {
		if ( $link->rel eq 'edit' )
		{
			$entry_obj->set_link('Edit' => $link->href);
		}
		else
		{
			$entry_obj->set_link($link->title => $link->href);
		}
	}

	# Get content
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

	$entry_obj->content($content_factory->new_object($hr));
	p $entry_obj;
	$collection->add_entry($entry_obj);
	}

p $collection;
