use CatalystX::Declare;

controller SGA::SharedCanvas::Base::Admin {

  final action end (@) isa RenderView;

  method doMethod (Str $method, $ctx, $collection, $params) {
    my $thing = eval { $collection -> $method($params) };

    my $e = $@;
    if($e) {
      if(blessed($e) && $e -> isa('SGA::SharedCanvas::Exception::PUT')) {
        $ctx -> stash -> {form_data} = $ctx -> request -> params;
        $ctx -> stash -> {error_msg} = $e -> message;
        $ctx -> stash -> {missing} = $e -> missing;
        $ctx -> stash -> {invalid} = $e -> invalid;
        return;
      }
      else {
        die $e; # rethrow
      }
    }
    return $thing;
  }

  method POST ($ctx, $collection, $params) { 
    $self -> doMethod('_POST', $ctx, $collection, $params);
  }

  method PUT ($ctx, $collection, $params) {
    $self -> doMethod('_PUT', $ctx, $collection, $params);
  }

  method DELETE ($ctx, $collection) {
    $self -> doMethod('_DELETE', $ctx, $collection, {});
  }

}
