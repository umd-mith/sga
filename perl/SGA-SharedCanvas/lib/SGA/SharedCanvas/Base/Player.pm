use CatalystX::Declare;

controller SGA::SharedCanvas::Base::Player
   extends Catalyst::Controller::REST
{

  under base {
    action play_base (Str $uuid) as '' {
      my $resource = $ctx -> stash -> {collection} -> resource($uuid);

      if(!$resource) {
        $ctx -> detach(qw/Controller::Root default/);
      }

      $ctx -> stash -> {resource} = $resource;
    }
  }

  final action end (@) isa RenderView;
}
