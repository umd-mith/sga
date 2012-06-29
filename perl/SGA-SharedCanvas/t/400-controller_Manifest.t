use strict;
use warnings;
use Test::More;
use HTTP::Request::Common;
use JSON;

BEGIN {
  $ENV{'SGA_SHAREDCANVAS_LOCAL_SUFFIX'} = 'testing';
}

#use Catalyst::Test 'SGA::SharedCanvas';

use lib './t/lib';
use t::REST;
use SGA::SharedCanvas::Controller::Manifest;

GET_ok( "/manifest", "Get list of manifests" );
GET_ok( "/manifest", "application/rdf", "Get list of manifests" );
GET_ok( "/manifest", "application/rdf+xml", "Get list of manifests" );

my $json = POST_ok( "/manifest", { label => "Foo" }, "Add a manifest" );
GET_ok( "/manifest", "application/rdf", "Get list of manifests" );
GET_ok( $json->{_links}->{self}, "Get added manifest" );

done_testing();
