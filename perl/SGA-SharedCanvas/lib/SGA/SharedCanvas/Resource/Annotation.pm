package SGA::SharedCanvas::Resource::Annotation;

use SGA::SharedCanvas::Resource;

rdf_type 'http://www.w3.org/ns/openannotation/core/Annotation';

has_many targets => (
);

# only 1 really, but this is easiest for now
has_many bodies => (
);

1;

__END__
