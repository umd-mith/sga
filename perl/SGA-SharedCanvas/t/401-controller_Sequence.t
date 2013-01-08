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
use SGA::SharedCanvas::Controller::Sequence;

GET_ok( "/sequence", "Get list of sequences" );
GET_ok( "/sequence", "application/rdf", "Get list of sequences" );
GET_ok( "/sequence", "application/rdf+xml", "Get list of sequences" );

my $json = POST_ok( "/sequence", { label => "Foo" }, "Add a sequence" );
GET_ok( "/sequence", "Get list of sequences" );
GET_ok( "/sequence", "application/rdf+json", "Get list of sequences" );
GET_ok( "/sequence", "application/rdf+xml", "Get list of sequences" );
GET_ok( $json->{_links}->{self}, "Get added sequence" );

done_testing();
