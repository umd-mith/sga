use CatalystX::Declare;

controller SGA::SharedCanvas::Controller::Manifest
   extends SGA::SharedCanvas::Base::ResourceController
{

  use SGA::SharedCanvas::Collection::Manifest;
  use SGA::SharedCanvas::Resource::Manifest;

  $CLASS -> config(
    map => {
      "application/rdf+json" => "RDF::JSON",
      "application/rdf+xml" => "RDF::XML",
      "text/turtle" => "RDF::Turtle",
    },
    default => 'text/html',
  );

  under '/' {
    action base as 'manifest' {
      $ctx -> stash -> {collection} = 
        SGA::SharedCanvas::Collection::Manifest -> new(
          c => $ctx
        );
    }
  }
}
