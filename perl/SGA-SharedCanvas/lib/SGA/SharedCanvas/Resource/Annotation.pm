package SGA::SharedCanvas::Resource::Annotation;

use SGA::SharedCanvas::Resource;

rdf_type 'http://www.w3.org/ns/openannotation/core/Annotation';

has_many targets => "SGA::SharedCanvas::Resource::Target", (
  predicate => 'http://www.w3.org/ns/openannotation/core/hasTarget',
);

# only 1 really, but this is easiest for now
has_one body => "SGA::SharedCanvas::Resource::Body", (
  predicate => 'http://www.w3.org/ns/openannotation/core/hasBody',
);

1;

__END__
