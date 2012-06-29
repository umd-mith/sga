package SGA::SharedCanvas::Resource::Manifest;

use SGA::SharedCanvas::Resource;

rdf_type 'http://dms.stanford.edu/ns/Manifest';

prop label => (
  is => 'rw',
  rdf_type => 'literal',
  rdf_property => 'http://www.w3.org/2001/01/rdf-schema#label',
);

#has_many layers => "SGA::SharedCanvas::Resource::Layer", (
#  source => sub { ... },
#);
#
#has_many text_annotation_lists => "SGA::SharedCanvas::Resource::TextAnnotationlist", (
#  source => sub { ... },
#);
#
#has_many image_annotation_lists => "SGA::SharedCanvas::Resource::ImageAnnotationList", (
#  source => sub { ... },
#);
 
has_many sequences => "SGA::SharedCanvas::Resource::Sequence", (
  is => 'rw',
  source => sub { $_[0] -> source -> sequences },
);

#has_many ranges => "SGA::SharedCanvas::Resource::Range", (
#  source => sub { ... },
#);

sub PUT {
  my($self, $data) = @_;

  my $sequences = delete $data -> {sequences};

  $self -> source -> update($data);

  # we handle sequences separately
  if($sequences) {
    my $sequence_collection = SGA::SharedCanvas::Collection::Sequence->new(
      c => $self -> c
    );

    my @sequences =
      grep { defined }
      map { $_ -> source }
      grep { defined }
      map { $sequence_collection -> resource_for_url($_) }
          @$sequences
    ;

    my(%orig) = (map { ($_ -> sequence -> uuid) = $_ } $self -> source -> manifest_sequence);
    for my $sequence (@sequences) {
      if($orig{$sequence->uuid}) {
        delete $orig{$sequence->uuid};
      }
      else {
        $self -> source -> manifest_sequence -> new({
          manifest_id => $self -> source -> id,
          sequence_id => $sequence -> id
        }) -> insert;
      }
    }
  
    for my $ms (values %orig) {
      $ms -> delete;
    }
  }

  $self;
}

1;

__END__
