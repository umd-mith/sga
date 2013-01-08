package SGA::SharedCanvas::Controller::Admin::Canvas;

use Moose;
use namespace::autoclean;

use SGA::SharedCanvas::Collection::Canvas;
use SGA::SharedCanvas::Resource::Canvas;

BEGIN {
  extends 'SGA::SharedCanvas::Base::Admin';
}

sub base :Chained('/') :PathPart('admin/canvas') :CaptureArgs(0) { }

sub index :Chained('base') :PathPart('') :Args(0) {
  my($self, $c) = @_;

  $c -> stash -> {canvases} = [
    SGA::SharedCanvas::Collection::Canvas -> new(c => $c) -> resources
  ];
  $c -> stash -> {template} = "/admin/content/canvases";
}

sub canvas_new :Chained('base') :PathPart('new') :Args(0) {
  my($self, $c) = @_;

  if($c -> request -> method eq 'POST') {
    my $collection = SGA::SharedCanvas::Collection::Canvas -> new(c => $c);
    my $params = $c -> request -> params;
    my $canvas = $self -> POST($c, $collection, $params);
    if($canvas) {
      $c -> response -> redirect($c->uri_for("/admin/canvas"));
    }
  }
  $c -> stash -> {template} = "admin/content/canvases/new";
}

sub canvas_base :Chained('base') :PathPart('') :CaptureArgs(1) {
  my($self, $c, $uuid) = @_;

  my $canvas = SGA::SharedCanvas::Collection::Canvas -> new(c => $c)
                                                     -> resource($uuid);
  if(!$canvas) {
    $c -> detach(qw/Controller::Root default/);
  }

  $c -> stash -> {canvas} = $canvas;
}

sub canvas_edit :Chained('canvas_base') :PathPart('') :Args(0) {
  my($self, $c) = @_;

  my $canvas = $c -> stash -> {canvas};

  if($c -> request -> method eq 'POST') {
    my $res = $self -> PUT($c, $canvas, $c -> request -> params);
    if($res) {
      $c -> response -> redirect($c -> uri_for("/admin/canvas"));
    }
  }
  else {
    $c -> stash -> {form_data} = {
      label => $canvas -> label,
      width => $canvas -> width,
      height => $canvas -> height,
    };
  }

  $c -> stash -> {template} = "/admin/content/canvases/edit";
}

1;

