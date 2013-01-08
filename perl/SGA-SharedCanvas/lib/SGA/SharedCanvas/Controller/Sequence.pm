use CatalystX::Declare;

controller SGA::SharedCanvas::Controller::Sequence
   extends SGA::SharedCanvas::Base::ResourceController
{

  use SGA::SharedCanvas::Collection::Sequence;
  use SGA::SharedCanvas::Resource::Sequence;

  $CLASS -> config(
    map => {
      "application/rdf+json" => "RDF::JSON",
      "application/rdf+xml" => "RDF::XML",
      "text/turtle" => "RDF::Turtle",
    },
    default => 'text/html',
  );

  under '/' {
    action base as 'sequence' {
      $ctx -> stash -> {collection} = 
        SGA::SharedCanvas::Collection::Sequence -> new(
          c => $ctx
        );
    }
  }
}
