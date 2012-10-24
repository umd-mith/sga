package SGA::SharedCanvas::Controller::Canvas;

use Moose;
use namespace::autoclean;

use SGA::SharedCanvas::Collection::Canvas;
use SGA::SharedCanvas::Resource::Canvas;

BEGIN {
  extends 'SGA::SharedCanvas::Base::ResourceController';
}

__PACKAGE__ -> config(
  map => {
    "application/rdf+json" => "RDF::JSON",
    "application/rdf+xml" => "RDF::XML",
  },
  default => 'text/html',
);

sub base :Chained('/') :PathPart('canvas') :CaptureArgs(0) {
  my($self, $c) = @_;

  $c -> stash -> {collection} = SGA::SharedCanvas::Collection::Canvas -> new(
    c => $c
  );
}

1;
