package SGA::SharedCanvas::Resource::TextAnnotation;

use SGA::SharedCanvas::Resource;
use namespace::autoclean;

rdf_type 'http://www.w3.org/ns/openannotation/core/Annotation';

#has_many constrained_canvases => 'SGA::SharedCanvas::Resource::ConstrainedCanvas', (
#  predicate => 'http://www.w3.org/ns/openannotation/core/hasTarget',
#);

#has_many constrained_zones => 'SGA::SharedCanvas::Resource::ConstrainedZone', (
#  predicate => 'http://www.w3.org/ns/openannotation/core/hasTarget',
#);


#has_a constrained_text => 'SGA::SharedCanvas::Resource::ConstrainedText', (
#  predicate => 'http://www.w3.org/ns/openannotation/core/hasBody',
#);

1;

__END__
