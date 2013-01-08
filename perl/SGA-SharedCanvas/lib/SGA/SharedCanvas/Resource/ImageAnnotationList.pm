package SGA::SharedCanvas::Resource::ImageAnnotationList;

use SGA::SharedCanvas::Resource;

rdf_type "http://dms.stanford.edu/ns/ImageAnnotationList";

has '+source' => (
  isa => 'SGA::SharedCanvas::Model::DB::ImageAnnotationList',
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

has_many image_annotations => 'SGA::SharedCanvas::Resource::ImageAnnotation', (
  is => 'rw',
  source => sub { 
    my @ia = $_[0] -> source -> image_annotations ;
    print STDERR "We have ", scalar(@ia), " image annotations in list\n";
    @ia;
  },
);

1;

__END__
