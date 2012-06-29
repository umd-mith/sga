package SGA::SharedCanvas::Resource::ImageAnnotation;

use SGA::SharedCanvas::Resource;

rdf_type 'http://www.w3.org/ns/openannotation/core/Annotation';
rdf_type 'http://dms.stanford.edu/ns/ContentAnnotation';
rdf_type 'http://dms.stanford.edu/ns/ImageAnnotation';

has_many targets => (
);

has_many images => (
);

prop label => (
  is => 'rw',
  rdf_type => 'literal',
  rdf_property => 'http://www.w3.org/2001/01/rdf-schema#label',
);


1;

__END__
