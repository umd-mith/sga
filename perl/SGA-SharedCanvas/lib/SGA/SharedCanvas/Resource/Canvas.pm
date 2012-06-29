package SGA::SharedCanvas::Resource::Canvas;

use SGA::SharedCanvas::Resource;

rdf_type 'http://dms.stanford.edu/ns/Canvas';

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

prop label => (
  is => 'rw',
  rdf_type => 'literal',
  rdf_property => 'http://www.w3.org/2001/01/rdf-schema#label',
);

sub PUT {
  my($self, $data) = @_;

  $self -> source -> update($data);
  $self;
}

1;

__END__
