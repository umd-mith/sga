use CatalystX::Declare;
use 5.012;

application SGA::SharedCanvas
    with ConfigLoader
    with Static::Simple

    with Params::Nested

    with Unicode::Encoding

    with StatusMessage

    with StackTrace
{

  use CatalystX::RoleApplicator;

  $CLASS -> apply_request_class_roles(qw[
    Catalyst::TraitFor::Request::REST::ForBrowsers
  ]);

  our $VERSION = '0.01';
  $VERSION = eval $VERSION;

  $CLASS -> config(
    name => 'SGA Shared Canvas Support',
    # Disable deprecated behavior needed by old applications
    disable_component_resolution_regex_fallback => 1,
    enable_catalyst_header => 1, # Send X-Catalyst header
    encoding => 'UTF-8',
    default_view => 'Mason',
    'Plugin::ConfigLoader' => {
      file => $CLASS -> path_to( 'conf' ),
    },
    'View::HTML' => {
      INCLUDE_PATH => [
        $CLASS -> path_to( qw/root src/ ),
      ],
    },
    static => {
      dirs => [
        'static',
      ],
    },
  );

}

__END__

=head1 NAME

SGA::SharedCanvas - Catalyst based application

=head1 SYNOPSIS

    script/sga_sharedcanvas_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<SGA::SharedCanvas::Controller::Root>, L<Catalyst>

=head1 AUTHOR

James Smith,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
