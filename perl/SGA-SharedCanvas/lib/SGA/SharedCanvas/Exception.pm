package SGA::SharedCanvas::Exception;

use Moose;
extends 'Throwable::Error';

use namespace::autoclean;

has status => (
  is => 'ro',
  isa => 'Int',
  default => 400,
);

sub bad_request { shift -> throw( @_, status => 400 ) }
sub forbidden   { shift -> throw( @_, status => 403 ) }
sub not_found   { shift -> throw( @_, status => 404 ) }
sub gone        { shift -> throw( @_, status => 410 ) }

1;
