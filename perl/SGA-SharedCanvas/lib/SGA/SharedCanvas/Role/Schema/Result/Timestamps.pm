package SGA::SharedCanvas::Role::Schema::Result::Timestamps;

use Moose::Role;
use namespace::autoclean;
use DateTime;

before insert => sub {
  my($self) = @_;

  $self -> created_at(DateTime -> now) if $self -> can('created_at');
  $self -> updated_at(DateTime -> now) if $self -> can('updated_at');
};

before update => sub {
  my($self) = @_;

  $self -> updated_at(DateTime -> now) if $self -> can('updated_at');
};

1;

