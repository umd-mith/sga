use CatalystX::Declare;

controller SGA::SharedCanvas::Controller::Play
   extends SGA::SharedCanvas::Base::Player
{

  $CLASS -> config(
    map => {
      #'text/html' => [ 'View', 'Mason' ],
    },
    default => 'text/html',
  );

  under '/' {
    action base as 'm' {
      $ctx -> stash -> {collection} = 
        SGA::SharedCanvas::Collection::Manifest -> new(
          c => $ctx,
        );
    }
  }

  under play_base {
    final action play as '' isa REST;
  }

  method play_GET ($ctx) {
    $ctx -> stash -> {template} = 'play/manifest';
  }
}
