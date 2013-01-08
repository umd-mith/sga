use CatalystX::Declare;

controller SGA::SharedCanvas::Controller::Layer
   extends SGA::SharedCanvas::Base::ResourceController
{

  use SGA::SharedCanvas::Collection::Layer;
  use SGA::SharedCanvas::Resource::Layer;

  $CLASS -> config(
    map => {
      "application/rdf+json" => "RDF::JSON",
      "application/rdf+xml" => "RDF::XML",
      "text/turtle" => "RDF::Turtle",
    },
    default => 'text/html',
  );

  under '/' {
    action base as 'layer' {
      $ctx -> stash -> {collection} = 
        SGA::SharedCanvas::Collection::Layer -> new(
          c => $ctx
        );
    }
  }
}
