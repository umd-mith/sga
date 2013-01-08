use CatalystX::Declare;

view SGA::SharedCanvas::View::HTML
  extends Catalyst::View::TT is mutable
{
  $CLASS->config(
    TEMPLATE_EXTENSION => '.tt2',
    render_die => 1,
    PRE_PROCESS => 'config/main.tt2',
    WRAPPER => 'site/wrapper.tt2',
    ABSOLUTE => 1,
    RELATIVE => 1,
    PRE_CHOMP => 1,
    POST_CHOMP => 1,
  );

  #
  # This is for the RESTful pieces of the app
  #
  before process ($ctx, $stash_key) {
    if($stash_key) {
      $ctx -> stash -> {data} = $ctx -> stash -> {$stash_key};
    }
  }
}

__END__

=head1 NAME

SGA::SharedCanvas::View::HTML - TT View for SGA::SharedCanvas

=head1 DESCRIPTION

TT View for SGA::SharedCanvas.

=head1 SEE ALSO

L<SGA::SharedCanvas>

=head1 AUTHOR

James Smith,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.
