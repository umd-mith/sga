package SGA::SharedCanvas::Controller::Admin::Sequence;

use Moose;
use namespace::autoclean;

use SGA::SharedCanvas::Collection::Sequence;
use SGA::SharedCanvas::Resource::Sequence;

BEGIN {
  extends 'SGA::SharedCanvas::Base::Admin';
}

sub base :Chained('/') :PathPart('admin/sequence') :CaptureArgs(0) { }

sub index :Chained('base') :PathPart('') :Args(0) {
  my($self, $c) = @_;

  $c -> stash -> {sequences} = [
    SGA::SharedCanvas::Collection::Sequence -> new(c => $c) -> resources
  ];
  $c -> stash -> {template} = "/admin/aggregation/sequences";
}

sub sequence_new :Chained('base') :PathPart('new') :Args(0) {
  my($self, $c) = @_;

  if($c -> request -> method eq 'POST') {
    my $collection = SGA::SharedCanvas::Collection::Sequence -> new(c => $c);
    my $params = $c -> request -> params;
    if($params->{_embedded}->{canvases}) {
      $params->{_embedded}->{canvases} = [ split(/,\s*/, $params->{_embedded}->{canvases}) ];
    }
    elsif($params->{"_embedded[canvases]"}) {
      $params->{_embedded}->{canvases} = [ split(/,\s*/, $params->{"_embedded[canvases]"}) ];
    }
   
    my $sequence = $self -> POST($c, $collection, $params);
    if($sequence) {
      $c -> response -> redirect($c->uri_for("/admin/sequence/" . $sequence->id));
    }
  }
  $c -> stash -> {canvases} = +{ map { $_->id => $_ } SGA::SharedCanvas::Collection::Canvas->new(c => $c) -> resources };
  $c -> stash -> {template} = "admin/aggregation/sequences/new";
}

sub sequence_base :Chained('base') :PathPart('') :CaptureArgs(1) {
  my($self, $c, $uuid) = @_;

  my $sequence = SGA::SharedCanvas::Collection::Sequence -> new(c => $c) -> resource($uuid);
  if(!$sequence) {
    $c -> detach(qw/Controller::Root default/);
  }
  $c -> stash -> {sequence} = $sequence;
}

sub sequence_edit :Chained('sequence_base') :PathPart('') :Args(0) {
  my($self, $c) = @_;

  my $sequence = $c -> stash -> {sequence};

  if($c -> request -> method eq 'POST') {
    my $params = $c -> request -> params;
    if($params->{_embedded}->{canvases}) {
      $params->{_embedded}->{canvases} = [ split(/,\s*/, $params->{_embedded}->{canvases}) ];
    }
    elsif($params->{"_embedded[canvases]"}) {
      $params->{_embedded}->{canvases} = [ split(/,\s*/, $params->{"_embedded[canvases]"}) ];
    }
    my $res = $self -> PUT($c, $sequence, $params);
    if($res) {
      $c -> response -> redirect($c -> uri_for("/admin/sequence"));
    }
  }
  else {
    $c -> stash -> {form_data} = {
      label => $sequence -> label,
      canvases => [ map { $_ -> id } @{$sequence -> canvases} ],
    };
  }
  $c -> stash -> {canvases} = +{ map { $_->id => $_ } SGA::SharedCanvas::Collection::Canvas->new(c => $c) -> resources };
  $c -> stash -> {template} = "/admin/aggregation/sequences/edit";
}

1;

