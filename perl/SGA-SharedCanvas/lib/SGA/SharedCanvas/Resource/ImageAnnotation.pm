package SGA::SharedCanvas::Resource::ImageAnnotation;

use SGA::SharedCanvas::Resource;

rdf_type 'http://www.w3.org/ns/openannotation/core/Annotation';
rdf_type 'http://dms.stanford.edu/ns/ContentAnnotation';
rdf_type 'http://dms.stanford.edu/ns/ImageAnnotation';

has_many canvases => "SGA::SharedCanvas::Resource::Canvas", (
  is => 'rw',
  predicate => 'http://www.w3.org/ns/openannotation/core/hasTarget',
);

#has_many zones => "SGA::SharedCanvas::Resource::Zone", (
#  is => 'rw',
#  predicate => 'http://www.w3.org/ns/openannotation/core/hasTarget',
#);

has_a image => "SGA::SharedCanvas::Resource::Image", (
  required => 1,
  is => 'rw',
  predicate => 'http://www.w3.org/ns/openannotation/core/hasBody',
);

prop id => (
  is => 'ro',
  source => sub { $_[0] -> source -> uuid },
);

prop label => (
  is => 'rw',
  rdf_type => 'literal',
  rdf_property => 'http://www.w3.org/2001/01/rdf-schema#label',
);


1;

__END__
