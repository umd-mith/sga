use CatalystX::Declare;

controller SGA::SharedCanvas::Controller::Canvas
   extends SGA::SharedCanvas::Base::ResourceController
{

  use SGA::SharedCanvas::Collection::Canvas;
  use SGA::SharedCanvas::Resource::Canvas;

  $CLASS -> config(
    map => {
      "application/rdf+json" => "RDF::JSON",
      "application/rdf+xml" => "RDF::XML",
      "text/turtle" => "RDF::Turtle",
    },
    default => 'text/html',
  );

  under '/' {
    action base as 'canvas' {
      $ctx -> stash -> {collection} = 
           SGA::SharedCanvas::Collection::Canvas -> new(
             c => $ctx
           );
    }
  }
}
