package SGA::SharedCanvas::Resource::Sequence;

use SGA::SharedCanvas::Resource;

rdf_type 'http://dms.stanford.edu/ns/Sequence';

prop label => (
  is => 'rw',
  rdf_type => 'literal',
  rdf_property => 'http://www.w3.org/2001/01/rdf-schema#label',
);

has_many canvases => 'SGA::SharedCanvas::Resource::Canvas', (
  is => 'rw',
  ordered => 1, # results in particular RDF serialization
  source => sub { $_[0] -> source -> canvases },
);

sub PUT {
  my($self, $data) = @_;

  my $canvases = delete $data -> {canvases};

  $self -> source -> update($data);

  if($canvases) {
    # this should be a list of URLs that correspond to canvases here
    # or simple UUIDs - which is what we'll decompose them into
    my $canvas_collection = SGA::SharedCanvas::Collection::Canvas->new(
      c => $self -> c
    );
    my @canvases = 
      grep { defined }
      map { $canvas_collection -> resource_for_url($_) -> source }
          @$canvases
    ;

    # now we go through and make sure the current list is in the same
    # order
    my(%orig) = (map { ($_ -> canvas -> uuid) => $_ } $self -> source -> canvas_sequence);
    my $i = 0;
    for my $canvas (@canvases) {
      if($orig{$canvas->uuid}) {
        $orig{$canvas->uuid}->move_to($i);
        delete $orig{$canvas->uuid};
      }
      else {
        $self -> source -> canvas_sequence -> new({
          canvas_id => $canvas->id,
          sequence_id => $self -> source -> id,
          position => $i,
        }) -> insert;
      }
      $i ++;
    }

    # now we need to remove anything left
    for my $cs (values %orig) {
      $cs -> delete;
    }
  }

  $self;
}


1;
