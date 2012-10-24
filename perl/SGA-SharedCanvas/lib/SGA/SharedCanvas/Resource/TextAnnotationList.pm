package SGA::SharedCanvas::Resource::TextAnnotationSet;

use SGA::SharedCanvas::Resource;

rdf_type "http://www.openarchives.org/ore/terms/Aggregation";
rdf_type "http://dms.stanford.edu/ns/TextAnnotationList";
rdf_type "http://www.w3.org/1999/02/22-rdf-syntax-ns#List";

prop label => (
  is => 'rw',
  rdf_type => 'literal',
  rdf_property => 'http://www.w3.org/2001/01/rdf-schema#label',
);

has_many annotations => (
  source => sub { ... },
);

1;

__END__
