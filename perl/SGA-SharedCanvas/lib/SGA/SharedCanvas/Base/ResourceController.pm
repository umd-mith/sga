use CatalystX::Declare;

controller SGA::SharedCanvas::Base::ResourceController
   extends Catalyst::Controller::REST
{

  under base {
    final action collection as '' isa REST;

    action resource_base (Str $id) as '' {
      my $resource = $ctx -> stash -> {collection} -> resource($id);
      if(!$resource) {
        $self -> status_not_found($ctx,
          message => "Resource not found."
        );
        $ctx -> detach;
      }

      $ctx -> stash -> {resource} = $resource;
    }
  }

  under resource_base {
    final action resource as '' isa REST;
  }

  method collection_GET ($ctx) {
    $self -> status_ok($ctx,
      entity => $ctx -> stash -> {collection} -> _GET(1)
    );
  }

  method collection_POST ($ctx) {
    my $manifest = $ctx -> stash -> {collection} -> POST($ctx -> req -> data);
    $self -> status_created($ctx,
      location => $manifest->link,
      entity => $manifest -> _GET(1)
    );
  }

  method resource_GET ($ctx) {
    $self -> status_ok($ctx,
      entity => $ctx -> stash -> {resource} -> _GET(1)
    );
  }

  method resource_PUT ($ctx) {
    my $resource = $ctx -> stash -> {resource} -> _PUT($ctx -> req -> data);
    $self -> status_ok($ctx,
      entity => $resource -> _GET(1)
    );
  }

  method resource_DELETE ($ctx) {
    if($ctx -> stash -> {resource} -> _DELETE) {
      $self -> status_no_content($ctx);
    }
    else {
      $self -> status_forbidden($ctx,
        message => "Unable to delete resource."
      );
    }
  }
}
