package SGA::SharedCanvas::Resource::Image;

use SGA::SharedCanvas::Resource;

#
# We need to send the file if the png/jpg/tiff/etc. are requested
#

media_type 'image/tiff'
media_type 'image/png'
media_type 'image/jpg'

prop format => (
  is => 'rw',
  rdf_type => 'literal',
  rdf_property => '

);

prop height => (
  is => 'rw',
  rdf_type => 'literal',
  rdf_property => 'http://www.w3.org/2003/12/exif/ns#height',
);

prop width => (
  is => 'rw',
  rdf_type => 'literal',
  rdf_property => 'http://www.w3.org/2003/12/exif/ns#width',
);

1;

__END__
