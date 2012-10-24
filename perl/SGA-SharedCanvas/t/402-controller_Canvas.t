use strict;
use warnings;
use Test::More;
use HTTP::Request::Common;
use JSON;

BEGIN {
  $ENV{'SGA_SHAREDCANVAS_LOCAL_SUFFIX'} = 'testing';
}

use lib './t/lib';
use t::REST;
use SGA::SharedCanvas::Controller::Canvas;

GET_ok( "/canvas", "Get list of canvases" );
GET_ok( "/canvas", "application/rdf", "Get list of canvases" );
GET_ok( "/canvas", "application/rdf+xml", "Get list of canvases" );

my $json = POST_ok( "/canvas", { label => "Foo", height => 1024, width => 768 }, "Add a canvas" );
GET_ok( "/canvas", "Get list of canvases" );
GET_ok( "/canvas", "application/rdf+json", "Get list of canvases" );
GET_ok( "/canvas", "application/rdf+xml", "Get list of canvases" );
GET_ok( $json->{_links}->{self}, "Get added canvas" );

#
# Now test adding canvas to a sequence
#

my $seq_json = POST_ok( "/sequence", { 
  label => "Bar",
  canvases => [ $json -> {_links} -> {self} ],
}, "Add a sequence" );

GET_ok( $seq_json -> {_links} -> {self}, "Get sequence" );
GET_ok( $seq_json -> {_links} -> {self}, "application/rdf+xml", "Get sequence" );

my $c2_json = POST_ok("/canvas", { label => "Foo-v", height => 1024, width => 768 }, "Add another canvas" );

PUT_ok( $seq_json -> {_links} -> {self}, {
  canvases => [ $c2_json -> {_links} -> {self},
                $json -> {_links} -> {self},
              ]
}, "Add another canvas before the first in the sequence");

my $seq2_json = GET_ok( $seq_json -> {_links} -> {self}, "Get modified sequence" );
GET_ok( $seq_json -> {_links} -> {self}, "application/rdf+xml", "Get modified sequence" );

my $manifest_json = POST_ok( "/manifest", {
  label => "Manifest",
  sequences => [ $seq_json -> {_links} -> {self} ],
}, "Add a manifest" );

GET_ok( $manifest_json -> {_links} -> {self}, "application/rdf+xml", "Get manifest" );
GET_ok( $manifest_json -> {_links} -> {self}, "application/rdf+json", "Get manifest" );

done_testing();
