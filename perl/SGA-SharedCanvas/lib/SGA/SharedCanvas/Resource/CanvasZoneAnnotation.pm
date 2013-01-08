package SGA::SharedCanvas::Resource::CanvasZoneAnnotation;

use SGA::SharedCanvas::Resource;

rdf_type 'http://www.w3.org/ns/openannotation/core/SpecificResource';

prop id => (
  is => 'ro',
  rdf_type => 'literal',
  source => sub { $_[0] -> uuid },
);

has_many canvases => "SGA::SharedCanvas::Resource::Canvas", (
  predicate => 'http://www.w3.org/ns/openannotation/core/hasSource',
);

belongs_to zone_annotation => "SGA::SharedCanvas::Resource::ZoneAnnotation";

contains_a fragment_selector => "SGA::SharedCanvas::Resource::FragmentSelector", (
  predicate => 'http://www.w3.org/ns/openannotation/core/hasSelector',
);

1;
