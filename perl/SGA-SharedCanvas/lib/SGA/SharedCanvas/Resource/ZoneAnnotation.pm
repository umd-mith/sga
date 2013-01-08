package SGA::SharedCanvas::Resource::ZoneAnnotation;

use SGA::SharedCanvas::Resource;

rdf_type 'http://www.w3.org/ns/openannotation/core/Annotation';

has_many canvases => "SGA::SharedCanvas::Resource::CanvasZoneAnnotation", (
  predicate => 'http://www.w3.org/ns/openannotation/core/hasTarget',
);

has_a zone => "SGA::SharedCanvas::Resource::Zone", (
  predicate => 'http://www.w3.org/ns/openannotation/core/hasBody',
);

prop label => (
  is => 'rw',
  rdf_type => 'literal',
  rdf_property => 'http://www.w3.org/2001/01/rdf-schema#label',
);

1;

__END__
