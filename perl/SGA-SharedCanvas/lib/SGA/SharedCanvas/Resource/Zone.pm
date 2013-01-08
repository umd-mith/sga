package SGA::SharedCanvas::Resource::Zone;

use SGA::SharedCanvas::Resource;

#
# We need to send the file if the png/jpg/tiff/etc. are requested
#

rdf_type 'http://www.w3.org/ns/openannotation/core/Zone';

prop id => (
  is => 'ro',
  source => sub { $_[0] -> source -> uuid },
);

prop label => (
  is => 'rw',
  rdf_type => 'literal',
  required => 1,
);

prop height => (
  is => 'rw',
  rdf_type => 'literal',
  rdf_property => 'http://www.w3.org/2003/12/exif/ns#height',
  required => 1,
);

prop width => (
  is => 'rw',
  rdf_type => 'literal',
  rdf_property => 'http://www.w3.org/2003/12/exif/ns#width',
  required => 1,
);

prop natural_angle => (
  is => 'rw',
  rdf_type => 'literal',
  rdf_property => 'http://www.w3.org/ns/openannotation/core/naturalAngle',
  default => 0,
);

1;

__END__
