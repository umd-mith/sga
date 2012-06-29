package Catalyst::Action::Serialize::RDF::XML;

use Moose;
use namespace::autoclean;

extends 'Catalyst::Action';
use RDF::Trine::Serializer::RDFXML;

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

# we expect the data to be an RDF::Trine::Model
sub serialize {
  my($self, $model) = @_;

  my $serializer = RDF::Trine::Serializer::RDFXML->new( 
    namespaces => {
      'sc' => 'http://dms.stanford.edu/ns/',
      'exif' => 'http://www.w3.org/2003/12/exif/ns#',
      'rdfs' => 'http://www.w3.org/2001/01/rdf-schema#',
      'ore' => 'http://www.openarchives.org/ore/terms/',
      'dc' => 'http://purl.org/dc/elements/1.1/',
      'dcterms' => 'http://purl.org/dc/terms/',
      'foaf' => 'http://xmlns.com/foaf/0.1/',
      'oa' => 'http://www.w3.org/ns/openannotation/core/',
      'oax' => 'http://www.w3.org/ns/openannotation/extension/',
      'oac' => 'http://www.openannotation.org/ns/',
      'cnt' => 'http://www.w3.org/2008/content#',
    },
  );
  $serializer->serialize_model_to_string($model);
}

1;

__END__
