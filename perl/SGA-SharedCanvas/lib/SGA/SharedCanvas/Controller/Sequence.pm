package SGA::SharedCanvas::Controller::Sequence;

use Moose;
use namespace::autoclean;

use SGA::SharedCanvas::Collection::Sequence;
use SGA::SharedCanvas::Resource::Sequence;

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

sub base :Chained('/') :PathPart('sequence') :CaptureArgs(0) {
  my($self, $c) = @_;

  $c -> stash -> {collection} = SGA::SharedCanvas::Collection::Sequence -> new(
    c => $c
  );
}

1;
