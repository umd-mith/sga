package SGA::SharedCanvas::Resource::FragmentSelector;

use SGA::SharedCanvas::Resource;

rdf_type 'http://www.w3.org/ns/openannotation/core/FragmentSelector';

prop value => (
  is => 'ro',
  rdf_type => 'literal',
  rdf_property => 'http://www.w3.org/2001/01/rdf-schema#value',
  source => sub {
    my($self) = @_;
    "xywh=" . join ",", ($self -> x, $self -> y, $self -> w, $self -> h);
  },
);

prop x => (
  is => 'rw',
  required => 1,
);

prop y => (
  is => 'rw',
  required => 1,
);

prop w => (
  is => 'rw',
  required => 1,
);

prop h => (
  is => 'rw',
  required => 1,
);

1;
