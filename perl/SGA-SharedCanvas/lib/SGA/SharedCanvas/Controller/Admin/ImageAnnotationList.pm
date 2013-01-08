package SGA::SharedCanvas::Controller::Admin::ImageAnnotationList;

use Moose;
use namespace::autoclean;

use SGA::SharedCanvas::Collection::ImageAnnotationList;
use SGA::SharedCanvas::Resource::ImageAnnotationList;

BEGIN {
  extends 'SGA::SharedCanvas::Base::Admin';
}

sub base :Chained('/') :PathPart('admin/image_annotation_list') :CaptureArgs(0) {
  my($self, $c) = @_;

  my $params = $c -> request -> params;
  if($params -> {embedded}) {
    $params -> {_embedded} = $params->{embedded};
  }
}

sub index :Chained('base') :PathPart('') :Args(0) {
  my($self, $c) = @_;

  $c -> stash -> {image_annotation_lists} = [
    SGA::SharedCanvas::Collection::ImageAnnotationList -> new(c => $c) -> resources
  ];
  $c -> stash -> {template} = "/admin/aggregation/images";
}

sub list_new :Chained('base') :PathPart('new') :Args(0) {
  my($self, $c) = @_;

  if($c -> request -> method eq 'POST') {
    my $anno_list = $self -> POST( $c,
      SGA::SharedCanvas::Collection::ImageAnnotationList->new(c => $c),
      $c -> request -> params
    );
    if($anno_list) {
      $c -> response -> redirect($c -> uri_for(
        "/admin/image_annotation_list"
      ));
    }
  }

  $c -> stash -> {image_annotations} = [
    SGA::SharedCanvas::Collection::ImageAnnotation -> new(c => $c) -> resources
  ];
  $c -> stash -> {template} = "/admin/aggregation/images/new";
}

sub list_base :Chained('base') :PathPart('') :CaptureArgs(1) {
  my($self, $c, $uuid) = @_;

  my $list = SGA::SharedCanvas::Collection::ImageAnnotationList -> new( c => $c ) ->
    resource( $uuid );
  if(!$list) {
    $c -> detach(qw/Controller::Root default/);
  }
  $c -> stash -> {image_annotation_list} = $list;
}

sub list_edit :Chained('list_base') :PathPart('') :Args(0) {
  my($self, $c) = @_;

  my $list = $c -> stash -> {image_annotation_list};

  if($c -> request -> method eq 'POST') {
    my $res = $self -> PUT($c, $list, $c -> request -> params);
    if($res) {
      $c -> response -> redirect($c -> uri_for("/admin/image_annotation_list"));
    }
  }
  else {
    $c -> stash -> {form_data} = {
      label => $list -> label,
      _embedded => {
        image_annotations => [ map { $_ -> id } @{$list -> image_annotations} ],
      }
    };
  }
  $c -> stash -> {image_annotations} = [
    SGA::SharedCanvas::Collection::ImageAnnotation -> new(c => $c) -> resources
  ];
  $c -> stash -> {template} = "/admin/aggregation/images/edit";
}

1;
