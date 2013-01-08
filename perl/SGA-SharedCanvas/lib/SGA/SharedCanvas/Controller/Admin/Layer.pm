package SGA::SharedCanvas::Controller::Admin::Layer;

use Moose;
use namespace::autoclean;

use SGA::SharedCanvas::Collection::Layer;
use SGA::SharedCanvas::Collection::ImageAnnotationList;
use SGA::SharedCanvas::Resource::Layer;

BEGIN {
  extends 'SGA::SharedCanvas::Base::Admin';
}

sub base :Chained('/') :PathPart('admin/layer') :CaptureArgs(0) { 
  my($self, $c) = @_;

  my $params = $c -> request -> params;
  if($params -> {embedded}) {
    $params -> {_embedded} = $params->{embedded};
  }
}

sub index :Chained('base') :PathPart('') :Args(0) {
  my($self, $c) = @_;

  $c -> stash -> {layers} = [
    SGA::SharedCanvas::Collection::Layer -> new(c => $c) -> resources
  ];

  $c -> stash -> {template} = "/admin/aggregation/layers";
}

sub layer_new :Chained('base') :PathPart('new') :Args(0) {
  my($self, $c) = @_;

  if($c -> request -> method eq 'POST') {
    my $layer = $self -> POST($c,
      SGA::SharedCanvas::Collection::Layer -> new(c => $c),
      $c -> request -> params
    );
    if($layer) {
      $c -> response -> redirect(
        $c -> uri_for("/admin/layer")
      );
    }
  }

  $c -> stash -> {image_annotation_lists} = [
    SGA::SharedCanvas::Collection::ImageAnnotationList->new(c => $c) -> resources
  ];
  $c -> stash -> {template} = "/admin/aggregation/layers/new";
}

sub layer_base :Chained('base') :PathPart('') :CaptureArgs(1) {
  my($self, $c, $uuid) = @_;

  my $layer = SGA::SharedCanvas::Collection::Layer->new(c=>$c)->resource($uuid);
  if(!$layer) {
    $c -> detach(qw/Controller::Root default/);
  }
  $c -> stash -> {layer} = $layer;
}

sub layer_edit :Chained('layer_base') :PathPart('') :Args(0) {
  my($self, $c) = @_;

  my $layer = $c -> stash -> {layer};

  if($c -> request -> method eq 'POST') {
    my $res= $self -> PUT($c, $layer, $c -> request -> params);
    if($res) {
      $c -> response -> redirect($c -> uri_for("/admin/layer"));
    }
  }
  else {
    $c -> stash -> {form_data} = {
      label => $layer -> label,
      _embedded => {
        image_annotation_lists => [ map { $_->id } @{$layer->image_annotation_lists} ],
      },
    };
  }
  $c -> stash -> {image_annotation_lists} = [
    SGA::SharedCanvas::Collection::ImageAnnotationList->new(c => $c) -> resources
  ];
  $c -> stash -> {template} = "/admin/aggregation/layers/edit";
}

1;
