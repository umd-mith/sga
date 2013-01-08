package Catalyst::Action::Deserialize::File;

use Moose;
use namespace::autoclean;
use Scalar::Util qw(openhandle);
use Data::Dumper ();

extends 'Catalyst::Action';

# we want to accept the body and treat it as a file upload
# the file will be in the upload key
sub execute {
  my $self = shift;
  my ( $controller, $c, $test ) = @_;

  if($@) {
    $c -> log -> debug("Could not load ..., refusing to deserialize: $@") if $c -> debug;
    return 0;
  }

  my $body = $c -> request -> body;
  my $data = {};
  if($body) {
    eval {
      if(openhandle $body) {
        seek($body, 0, 0);
      }
      $data->{file} = $body;
      $data->{size} = (stat $body)[7];
      $data->{type} = $c -> request -> content_type;
    };
    if($@) {
      return $@;
    }
    $c -> request -> data( $data );
  }
  else {
    $c -> log -> debug(
      'I would have deserialized, but there was nothing in the body!')
        if $c->debug;
  }
  print STDERR Data::Dumper->Dump([$data]);
  return 1;
}

__PACKAGE__ -> meta -> make_immutable;

1;
