use CatalystX::Declare;

controller SGA::SharedCanvas::Controller::Admin {

  final action index as '' {
    # assume authenticated for now
    $ctx -> response -> redirect($ctx -> uri_for('/admin/manifest'));
  }

  final action end (@) isa RenderView;

}
