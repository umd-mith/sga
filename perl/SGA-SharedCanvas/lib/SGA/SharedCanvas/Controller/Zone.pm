use CatalystX::Declare;

controller SGA::SharedCanvas::Controller::Zone
   extends SGA::SharedCanvas::Base::ResourceController
{

  use SGA::SharedCanvas::Collection::Zone;
  use SGA::SharedCanvas::Resource::Zone;

  $CLASS -> config(
    map => {
      "application/rdf+json" => "RDF::JSON",
      "application/rdf+xml" => "RDF::XML",
      "text/turtle" => "RDF::Turtle",
    },
    default => 'text/html',
  );

  under '/' {
    action base as 'zone' {
      $ctx -> stash -> {collection} = 
        SGA::SharedCanvas::Collection::Zone -> new(
          c => $ctx
        );
    }
  }

  under resource_base {
    action annotations_base as 'annotation' {
      $ctx -> stash -> {collection} = 
        SGA::SharedCanvas::Collection::ZoneAnnotation -> new(
          c => $ctx,
          zone => $ctx -> stash -> {resource}
        );
    }
  }

  under annotations_base {
    final action annotations as '' isa REST;

    action annotation_base (Str $uuid) as '' {
      $ctx -> stash -> {resource} =
         $ctx -> stash -> {collection} -> resource($uuid);
    }
  }

  under annotation_base {
    final action annotation as '' isa REST;
  }

  method annotations_GET ($ctx) { $self -> collection_GET($ctx); }
  method annotations_POST ($ctx) { $self -> collection_POST($ctx); }
  method annotations_OPTIONS ($ctx) { $self -> collection_OPTIONS($ctx); }

  method annotation_GET ($ctx) { $self -> resource_GET($ctx); }
  method annotation_PUT ($ctx) { $self -> resource_PUT($ctx); }
  method annotation_DELETE ($ctx) { $self -> resource_DELETE($ctx); }
  method annotation_OPTIONS ($ctx) { $self -> resource_OPTIONS($ctx); }
}
