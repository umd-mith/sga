package SGA::SharedCanvas::Resource::Image;

use SGA::SharedCanvas::Resource;

use Image::Info qw(image_info);
use File::Copy qw(cp);

rdf_type "http://www.w3.org/ns/openannotation/core/SpecificResource";

#
# We need to send the file if the png/jpg/tiff/etc. are requested
#
# POST/PUT requires an image file - other formats are not accepted
#

media_format 'image/tiff';
media_format 'image/png';
media_format 'image/jpg';

prop id => (
  is => 'ro',
  source => sub { $_[0] -> source -> uuid },
);

#
# These properties are modified via PUTting a new image, not by PUTting
# JSON or RDF.
#
prop format => (
  is => 'ro',
  rdf_type => 'literal',
  rdf_property => 'http://purl.org/dc/elements/1.1/format',
);

prop height => (
  is => 'ro',
  rdf_type => 'literal',
  rdf_property => 'http://www.w3.org/2003/12/exif/ns#height',
);

prop width => (
  is => 'ro',
  rdf_type => 'literal',
  rdf_property => 'http://www.w3.org/2003/12/exif/ns#width',
);

prop size => (
  is => 'ro',
  rdf_type => 'literal',
);

prop url => (
  is => 'rw',
  source => sub { $_[0] -> source -> url || $_[0] -> link },
  rdf_property => "http://www.w3.org/ns/openannotation/core/hasSource",
);

prop label => (
  is => 'rw',
  source => sub { $_[0] -> source -> label },
  rdf_property => "http://www.w3.org/2001/01/rdf-schema#label",
);
prop id => (
  is => 'ro',
  source => sub { $_[0] -> source -> uuid },
);

belongs_to_many image_annotations => 'SGA::SharedCanvas::Resource::ImageAnnotation', (
  is => 'rw',
  source => sub { $_[0] -> source -> image_annotations },
);
  

sub PUT_raw {
  my($self, $data) = @_;

  my $img_info = image_info($data->{file});
  my $info = {
    size => $data->{size},
    format => $img_info -> {file_media_type},
    width => $img_info -> {width},
    height => $img_info -> {height},
  };

  $self -> source -> set_inflated_columns($info);
  $self -> source -> insert_or_update;

  my $fname = $self -> source -> uuid;

  print STDERR "temp file:", $data->{file}->filename,"\n";

  print STDERR "Copying...\n";
  my $cp = cp $data->{file}->filename, $self -> c -> path_to(qw/uploads image/, $fname);
  print STDERR "  result of copy: $cp\n";

  $self;
}

sub GET_raw {
  my($self) = @_;

  my $json = { };

  open my $fh, "<", $self -> c -> path_to(qw/uploads image/, $self -> source -> uuid);
  binmode $fh;
  $json -> {file} = $fh;
  $json;
}

1;

__END__
