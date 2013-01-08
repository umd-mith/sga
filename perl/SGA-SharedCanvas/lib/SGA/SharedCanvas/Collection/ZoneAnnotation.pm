package SGA::SharedCanvas::Collection::ZoneAnnotation;

use SGA::SharedCanvas::Collection;
use namespace::autoclean;

has zone => (
  is => 'rw',
  predicate => 'has_zone',
);

override POST => sub {
  my($self, $data) = @_;

  if($self -> has_zone && !$data->{zone}) {
    $data->{zone} = $self -> zone -> source -> uuid
  }

  super;
};

sub constrain_collection {
  my($self, $q) = @_;

  if($self -> has_zone) {
    $q = $q -> search({
      "me.zone_id" => $self -> zone -> source -> id
    });
  }

  $q;
}

1;

