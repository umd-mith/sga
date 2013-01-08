#! /usr/bin/perl

use RDF::Trine;
use RDF::Trine::Parser;

# parse file as XML into RDF model
# export model as JSON after calling -> as_hashref

sub serialize {
  JSON::to_json( $_[0] -> as_hashref, { pretty => 1 } );
}

sub deserialize {
  my($base_uri, $fh, $model) = @_;
  my $parser = RDF::Trine::Parser -> new( 'rdfxml' );
  $parser -> parse_file_into_model( $base_uri, $fh, $model );
}

my $model = RDF::Trine::Model -> temporary_model;
deserialize("", \*STDIN, $model);
print serialize($model);
