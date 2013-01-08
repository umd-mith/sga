package SGA::SharedCanvas::Controller::Admin::Zone;

use Moose;
use namespace::autoclean;

use SGA::SharedCanvas::Collection::Zone;
use SGA::SharedCanvas::Resource::Zone;

BEGIN {
  extends 'SGA::SharedCanvas::Base::Admin';
}

sub base :Chained('/') :PathPart('admin/zone') :CaptureArgs(0) { }

sub index :Chained('base') :PathPart('') :Args(0) {
  my($self, $c) = @_;

  $c -> stash -> {zones} = [
    SGA::SharedCanvas::Collection::Zone -> new(c => $c) -> resources
  ];
  $c -> stash -> {template} = "/admin/content/zones";
}

sub zone_new :Chained('base') :PathPart('new') :Args(0) {
  my($self, $c) = @_;

  if($c -> request -> method eq 'POST') {
    my $collection = SGA::SharedCanvas::Collection::Zone -> new(c => $c);
    my $params = $c -> request -> params;
    my $zone = $self -> POST($c, $collection, $params);
    if($zone) {
      $c -> response -> redirect($c->uri_for("/admin/zone/" . $zone->id));
    }
  }
  $c -> stash -> {template} = "admin/content/zones/new";
}

1;

