package SGA::SharedCanvas::Resource::Layer;

use SGA::SharedCanvas::Resource;

#rdf_type 'http://dms.stanford.edu/ns/Manifest'

prop label => (
  is => 'rw',
  rdf_type => 'literal',
  rdf_property => 'http://www.w3.org/2001/01/rdf-schema#label',
);

has_many text_annotation_lists => (
  source => sub { ... },
);

has_many image_annotation_lists => (
  source => sub { ... },
);
 
1;

__END__
