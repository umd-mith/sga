use CatalystX::Declare;

controller SGA::SharedCanvas::Controller::Root
   extends Catalyst::Controller::REST
{
  use Lingua::EN::Inflect qw(PL_N);
  use Module::Load ();
  use String::CamelCase qw(wordsplit);

  $CLASS->config(
    namespace => '',
    map => {
      'text/html' => [ 'View', 'Mason' ],
    },
    default => 'text/html',
  );


  under '/' {
    final action index as '' isa REST;

    final action default (@) {
      $ctx->response->body( 'Page not found' );
      $ctx->response->status(404);
    }
  }

  method index_GET ($ctx) {
    my %embeddings = (
      manifests => 'Manifest',
      canvases => 'Canvas',
      sequences => 'Sequence',
      images => 'Image',
      image_annotations => 'ImageAnnotation',
      image_annotation_lists => 'ImageAnnotationList'
    );

    my $entity = {
      _links => {
        self => $ctx -> uri_for('/') -> as_string,
      },
      _embedded => [],
    };

    for my $id (qw/manifests canvases sequences images image_annotation_lists image_annotations/) {
      my $type = $embeddings{$id};
      my $class = "SGA::SharedCanvas::Collection::$type";
      eval { Module::Load::load($class) };
      next if $@;
      my $collection = $class -> new(c => $ctx);
      my $label = PL_N(join(" ", wordsplit($type)));
      my $info = {
        _links => { self => $collection -> link },
        dataType => $type,
        label => $label,
        id => $id,
        schema => $collection->schema,
      };
      push @{$entity->{_embedded}}, $info;
    }

    $self -> status_ok($ctx, entity => $entity);
  }
}

=head1 NAME

SGA::SharedCanvas::Controller::Root - Root Controller for SGA::SharedCanvas

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 index

The root page (/)

=cut

=head2 default

Standard 404 error page

=cut

=head2 end

Attempt to render a view, if needed.

=cut

#sub end : ActionClass('RenderView') {}

=head1 AUTHOR

James Smith,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.
