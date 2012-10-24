package SGA::SharedCanvas::Controller::Manifest;

use Moose;
use namespace::autoclean;

use SGA::SharedCanvas::Collection::Manifest;
use SGA::SharedCanvas::Resource::Manifest;

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

sub base :Chained('/') :PathPart('manifest') :CaptureArgs(0) {
  my($self, $c) = @_;

  $c -> stash -> {collection} = SGA::SharedCanvas::Collection::Manifest -> new(
    c => $c
  );
}

1;
