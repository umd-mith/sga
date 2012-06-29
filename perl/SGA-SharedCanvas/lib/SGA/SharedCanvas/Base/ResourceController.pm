package SGA::SharedCanvas::Base::ResourceController;

use Moose;
use namespace::autoclean;

BEGIN {
  extends 'Catalyst::Controller::REST';
}

sub collection :Chained('base') :PathPart('') :Args(0) :ActionClass('REST') { }

sub collection_GET {
  my($self, $c) = @_;

  $self -> status_ok($c,
    entity => $c -> stash -> {collection} -> _GET(1)
  );
}

sub collection_POST {
  my($self, $c) = @_;

  my $manifest = $c -> stash -> {collection} -> POST($c -> req -> data);
  $self -> status_created($c,
    location => $manifest->link,
    entity => $manifest -> _GET(1)
  );
}

sub resource :Chained('base') :PathPart('') :Args(1) :ActionClass('REST') {
  my($self, $c, $id) = @_;

  my $resource = $c -> stash -> {collection} -> resource($id);
  if(!$resource) {
    $self -> status_not_found($c,
      message => "Resource not found."
    );
    $c -> detach;
  }

  $c -> stash -> {resource} = $resource;
}

sub resource_GET {
  my($self, $c) = @_;

  $self -> status_ok($c,
    entity => $c -> stash -> {resource} -> _GET(1)
  );
}

sub resource_PUT {
  my($self, $c) = @_;

  my $resource = $c -> stash -> {resource} -> _PUT($c -> req -> data);
  $self -> status_ok($c,
    entity => $resource -> _GET(1)
  );
}

sub resource_DELETE {
  my($self, $c) = @_;

  if($c -> stash -> {resource} -> _DELETE) {
    $self -> status_no_content($c);
  }
  else {
    $self -> status_forbidden($c,
      message => "Unable to delete resource."
    );
  }
}

1;
