use CatalystX::Declare;

controller SGA::SharedCanvas::Controller::ZoneAnnotation
   extends SGA::SharedCanvas::Base::ResourceController
{

  use SGA::SharedCanvas::Collection::ZoneAnnotation;
  use SGA::SharedCanvas::Resource::ZoneAnnotation;

  $CLASS -> config(
    map => {
      "application/rdf+json" => "RDF::JSON",
      "application/rdf+xml" => "RDF::XML",
      "text/turtle" => "RDF::Turtle",
    },
    default => 'text/html',
  );

  under '/' {
    action base as 'zone_annotation' {
      $ctx -> stash -> {collection} = 
        SGA::SharedCanvas::Collection::ZoneAnnotation -> new(
          c => $ctx
        );
    }
  }
}
