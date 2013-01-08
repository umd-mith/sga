use CatalystX::Declare;

controller SGA::SharedCanvas::Controller::CanvasZoneAnnotation
   extends SGA::SharedCanvas::Base::ResourceController
{

  use SGA::SharedCanvas::Collection::CanvasZoneAnnotation;
  use SGA::SharedCanvas::Resource::CanvasZoneAnnotation;

  $CLASS -> config(
    map => {
      "application/rdf+json" => "RDF::JSON",
      "application/rdf+xml" => "RDF::XML",
      "text/turtle" => "RDF::Turtle",
    },
    default => 'text/html',
  );

  under '/' {
    action base as 'canvas_zone_annotation' {
      $ctx -> stash -> {collection} = 
        SGA::SharedCanvas::Collection::CanvasZoneAnnotation -> new(
          c => $ctx
      );
    }
  }
}
