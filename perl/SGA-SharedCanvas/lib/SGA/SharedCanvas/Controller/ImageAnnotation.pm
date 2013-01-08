use CatalystX::Declare;

controller SGA::SharedCanvas::Controller::ImageAnnotation
   extends SGA::SharedCanvas::Base::ResourceController
{

  use SGA::SharedCanvas::Collection::ImageAnnotation;
  use SGA::SharedCanvas::Resource::ImageAnnotation;

  $CLASS -> config(
    map => {
      "application/rdf+json" => "RDF::JSON",
      "application/rdf+xml" => "RDF::XML",
      "text/turtle" => "RDF::Turtle",
    },
    default => 'text/html',
  );

  under '/' {
    action base as 'image_annotation' {
      $ctx -> stash -> {collection} = 
        SGA::SharedCanvas::Collection::ImageAnnotation -> new(
          c => $ctx
        );
    }
  }
}
