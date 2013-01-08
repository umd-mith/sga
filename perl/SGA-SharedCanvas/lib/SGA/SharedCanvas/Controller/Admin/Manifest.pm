package SGA::SharedCanvas::Controller::Admin::Manifest;

use Moose;
use namespace::autoclean;

use SGA::SharedCanvas::Collection::Manifest;
use SGA::SharedCanvas::Collection::Layer;
use SGA::SharedCanvas::Collection::Sequence;
use SGA::SharedCanvas::Resource::Manifest;

BEGIN {
  extends 'SGA::SharedCanvas::Base::Admin';
}

sub base :Chained('/') :PathPart('admin/manifest') :CaptureArgs(0) { }

sub index :Chained('base') :PathPart('') :Args(0) {
  my($self, $c) = @_;

  $c -> stash -> {manifests} = [
    SGA::SharedCanvas::Collection::Manifest -> new(c => $c) -> resources
  ];
  $c -> stash -> {template} = "/admin/aggregation/manifests";
}

sub manifest_new :Chained('base') :PathPart('new') :Args(0) {
  my($self, $c) = @_;

  if($c -> request -> method eq 'POST') {
    my $collection = SGA::SharedCanvas::Collection::Manifest -> new(c => $c);
    my $params = $c -> request -> params;
    my $manifest = $self -> POST($c, $collection, $params);
    if($manifest) {
      $c -> response -> redirect($c->uri_for("/admin/manifest/" . $manifest->id));
    }
  }
  $c -> stash -> {template} = "admin/aggregation/manifests/new";
}

sub manifest_base :Chained('base') :PathPart('') :CaptureArgs(1) {
  my($self, $c, $uuid) = @_;

  my $manifest = SGA::SharedCanvas::Collection::Manifest -> new(c => $c) -> resource($uuid);
  if(!$manifest) {
    $c -> detach(qw/Controller::Root default/);
  }
  $c -> stash -> {manifest} = $manifest;
}

sub manifest_edit :Chained('manifest_base') :PathPart('') :Args(0) {
  my($self, $c) = @_;

  my $manifest = $c -> stash -> {manifest};

  if($c -> request -> method eq 'POST') {
    my $res = $self -> PUT($c, $manifest, $c -> request -> params);
    if($res) {
      $c -> response -> redirect($c -> uri_for("/admin/manifest"));
    }
  }
  else {
    $c -> stash -> {form_data} = {
      label => $manifest -> label,
      object_creator => $manifest -> object_creator,
      layers => [ map { $_ -> id } @{$manifest -> layers} ],
      sequences => [ map { $_ -> id } @{$manifest -> sequences} ],
    };
  }
  $c -> stash -> {layers} = [ SGA::SharedCanvas::Collection::Layer->new(c => $c) -> resources ];
  $c -> stash -> {sequences} = [ SGA::SharedCanvas::Collection::Sequence->new(c => $c) -> resources ];
  $c -> stash -> {template} = "/admin/aggregation/manifests/edit";
}

1;
