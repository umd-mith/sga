package SGA::SharedCanvas::Resource::Layer;

use SGA::SharedCanvas::Resource;

rdf_type 'http://dms.stanford.edu/ns/Layer';

prop id => (
  is => 'ro',
  source => sub { $_[0] -> source -> uuid },
);

prop label => (
  is => 'rw',
  rdf_type => 'literal',
  rdf_property => 'http://www.w3.org/2001/01/rdf-schema#label',
);

#has_many text_annotation_lists => 'SGA::SharedCanvas::Resource::TextAnnotationList', (
#);

has_many image_annotation_lists => 'SGA::SharedCanvas::Resource::ImageAnnotationList', (
  is => 'rw',
  source => sub { $_[0] -> source -> image_annotation_lists },
);

1;

__END__
