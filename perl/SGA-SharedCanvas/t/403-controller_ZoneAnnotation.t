use strict;
use warnings;
use Test::More;
use HTTP::Request::Common;
use JSON;

BEGIN {
  $ENV{'CATALYST_CONFIG_LOCAL_SUFFIX'} = 'testing';
}

use lib './t/lib';
use t::REST;
use SGA::SharedCanvas::Controller::ZoneAnnotation;

GET_ok( "/zone_annotation", "Get list of zone annotations" );
GET_ok( "/zone_annotation", "application/rdf", "Get list of zone annotations" );
GET_ok( "/zone_annotation", "application/rdf+xml", "Get list of zone annotations" );

my $json = POST_ok( "/canvas", { label => "Foo", height => 1024, width => 768 }, "Add a canvas" );
GET_ok( $json->{_links}->{self}, "Get added canvas" );
my $canvas_link = $json->{_links}->{self};

$json = POST_ok( "/zone", { label => "Bar", height => 512, width => 384 }, "Add a zone" );
GET_ok( $json->{_links}->{self}, "Get added zone" );
my $zone_link = $json -> {_links} -> {self};

$json = POST_ok( $zone_link . "/annotation", {}, "Add a zone annotation" );
my $anno_link = $json -> {_links} -> {self};


done_testing();
