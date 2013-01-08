package SGA::SharedCanvas::Resource::Manifest;

use SGA::SharedCanvas::Resource;

rdf_type 'http://dms.stanford.edu/ns/Manifest';

prop id => (
  is => 'ro',
  source => sub { $_[0] -> source -> uuid },
);

prop label => (
  is => 'rw',
  rdf_type => 'literal',
  rdf_property => 'http://www.w3.org/2001/01/rdf-schema#label',
);

prop object_creator => (
  is => 'rw',
  rdf_type => 'literal',
  rdf_property => 'http://dms.stanford.edu/ns/objectCreator',
);

prop object_date => (
  is => 'rw',
  rdf_type => 'literal',
  rdf_property => 'http://dms.stanford.edu/ns/objectDate',
);

has_many layers => "SGA::SharedCanvas::Resource::Layer", (
  is => 'rw',
  source => sub { $_[0] -> source -> layers },
);

#has_many text_annotation_lists => "SGA::SharedCanvas::Resource::TextAnnotationlist", (
#  source => sub { ... },
#);

has_many image_annotation_lists => "SGA::SharedCanvas::Resource::ImageAnnotationList", (
  is => 'rw',
  source => sub { $_[0] -> source -> image_annotation_lists },
);
 
has_many sequences => "SGA::SharedCanvas::Resource::Sequence", (
  is => 'rw',
  source => sub { $_[0] -> source -> sequences },
);

#has_many ranges => "SGA::SharedCanvas::Resource::Range", (
#  source => sub { ... },
#);

1;

__END__
