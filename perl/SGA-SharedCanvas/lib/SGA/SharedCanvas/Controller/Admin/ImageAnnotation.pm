package SGA::SharedCanvas::Controller::Admin::ImageAnnotation;

use Moose;
use namespace::autoclean;

use SGA::SharedCanvas::Collection::ImageAnnotation;
use SGA::SharedCanvas::Resource::ImageAnnotation;

use MooseX::Types::Moose qw( ArrayRef );

BEGIN {
  extends 'SGA::SharedCanvas::Base::Admin';
}

sub base :Chained('/') :PathPart('admin/image_annotation') :CaptureArgs(0) { 
  my($self, $c) = @_;

  my $params = $c -> request -> params;
  if($params -> {embedded}) {
    $params -> {_embedded} = $params->{embedded};
  }
}

sub index :Chained('base') :PathPart('') :Args(0) {
  my($self, $c) = @_;

  $c -> stash -> {image_annotations} = [
    SGA::SharedCanvas::Collection::ImageAnnotation -> new(c => $c) -> resources
  ];
  $c -> stash -> {template} = "/admin/annotation/images";
}

sub image_new :Chained('base') :PathPart('new') :Args(0) {
  my($self, $c) = @_;

  if($c -> request -> method eq 'POST') {
    my $collection = SGA::SharedCanvas::Collection::ImageAnnotation -> new(c => $c);
    my $params = $c -> request -> params;
    if(exists($params->{_embedded}) && exists($params->{_embedded}->{canvases}) && defined($params->{_embedded} -> {canvases}) && !is_ArrayRef($params->{_embedded} -> {canvases})) {
      $params->{_embedded} -> {canvases} = [ $params->{_embedded} -> {canvases} ];
    }
    my $image = $self -> POST($c, $collection, $params);
    if($image) {
      $c -> response -> redirect($c->uri_for("/admin/image_annotation/" . $image->id));
    }
  }
  $c -> stash -> {images} = [
    SGA::SharedCanvas::Collection::Image -> new(c => $c) -> resources
  ];
  $c -> stash -> {canvases} = [
    SGA::SharedCanvas::Collection::Canvas -> new(c => $c) -> resources
  ];
  $c -> stash -> {template} = "/admin/annotation/images/new";
}

sub image_base :Chained('base') :PathPart('') :CaptureArgs(1) {
  my($self, $c, $uuid) = @_;

  my $image = SGA::SharedCanvas::Collection::ImageAnnotation->new(c => $c) -> resource($uuid);
  if(!$image) {
    $c -> detach(qw/Controller::Root default/);
  }
  $c -> stash -> {image_annotation} = $image;
}

sub image_edit :Chained('image_base') :PathPart('') :Args(0) {
  my($self, $c) = @_;

  my $image = $c -> stash -> {image_annotation};
  if($c -> request -> method eq 'POST') {
    my $params = $c -> request -> params;
    use Data::Dumper ();
    print STDERR Data::Dumper->Dump([$params]);
    if(exists($params->{_embedded}) && exists($params->{_embedded}->{canvases}) && defined($params->{_embedded} -> {canvases}) && !is_ArrayRef($params->{_embedded} -> {canvases})) {
      $params->{_embedded} -> {canvases} = [ $params->{_embedded} -> {canvases} ];
    }
    my $res = $self -> PUT($c, $image, $params);
    if($res) {
      $c -> response -> redirect($c -> uri_for("/admin/image_annotation"));
    }
  }
  else {
    $c -> stash -> {form_data} = {
      label => $image -> label,
      _embedded => { 
        canvases => [ map { $_ -> id } @{$image -> canvases||[]} ],
      },
      image => $image -> image -> id,
    };
  }
  $c -> stash -> {images} = [
    SGA::SharedCanvas::Collection::Image -> new(c => $c) -> resources
  ];
  $c -> stash -> {canvases} = [
    SGA::SharedCanvas::Collection::Canvas -> new(c => $c) -> resources
  ];
  $c -> stash -> {template} = "/admin/annotation/images/edit";
}

1;

