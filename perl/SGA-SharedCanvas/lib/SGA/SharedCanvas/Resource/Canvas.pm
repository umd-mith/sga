package SGA::SharedCanvas::Resource::Canvas;

use SGA::SharedCanvas::Resource;

rdf_type 'http://dms.stanford.edu/ns/Canvas';

prop height => (
  is => 'rw',
  required => 1,
  rdf_type => 'literal',
  rdf_property => 'http://www.w3.org/2003/12/exif/ns#height',
  rdf_datatype => 'http://www.w3.org/2001/XMLSchema#integer',
);

prop width => (
  is => 'rw',
  required => 1,
  rdf_type => 'literal',
  rdf_property => 'http://www.w3.org/2003/12/exif/ns#width',
  rdf_datatype => 'http://www.w3.org/2001/XMLSchema#integer',
);

prop label => (
  is => 'rw',
  required => 1,
  rdf_type => 'literal',
  rdf_property => 'http://purl.org/dc/elements/1.1/title',
);

prop id => (
  is => 'ro',
  source => sub { $_[0] -> source -> uuid },
);

1;

__END__
