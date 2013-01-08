package SGA::SharedCanvas::Resource::TextAnnotationSet;

use SGA::SharedCanvas::Resource;

rdf_type "http://dms.stanford.edu/ns/TextAnnotationList";

prop label => (
  is => 'rw',
  rdf_type => 'literal',
  rdf_property => 'http://www.w3.org/2001/01/rdf-schema#label',
);

has_many text_annotations => 'SGA::SharedCanvas::Resource::TextAnnotation', (
  is => 'rw',
);

1;

__END__
