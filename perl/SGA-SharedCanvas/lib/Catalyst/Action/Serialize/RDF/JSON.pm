package Catalyst::Action::Serialize::RDF::JSON;

use Moose;
use namespace::autoclean;

extends 'Catalyst::Action';
use JSON ();
use Data::UUID ();

sub execute {
  my($self, $controller, $c) = @_;

  my $stash_key = (
    $controller -> {'serialize'} ?
      $controller->{'serialize'}->{'stash_key'} :
      $controller->{'stash_key'}
    ) || 'rest';

  my $output = $self -> serialize($c -> stash -> {$stash_key});
  $c -> response -> output( $output );
  return 1;
}

sub serialize { 
  JSON::to_json($_[1] -> as_hashref, {pretty => 1})
}

1;

__END__
