use CatalystX::Declare;

controller SGA::SharedCanvas::Controller::ImageAnnotationList
   extends SGA::SharedCanvas::Base::ResourceController
{

  use SGA::SharedCanvas::Collection::ImageAnnotationList;
  use SGA::SharedCanvas::Resource::ImageAnnotationList;

  $CLASS -> config(
    map => {
      "application/rdf+json" => "RDF::JSON",
      "application/rdf+xml" => "RDF::XML",
      "text/turtle" => "RDF::Turtle",
    },
    default => 'text/html',
  );

  under '/' {
    action base as 'image_annotation_list' {
      $ctx -> stash -> {collection} = 
        SGA::SharedCanvas::Collection::ImageAnnotationList -> new(
          c => $ctx
      );
    }
  }
}
