package SGA::SharedCanvas::Base::ResourceCollection;

use Moose;
use namespace::autoclean;

use String::CamelCase qw(decamelize);
use Lingua::EN::Inflect qw(PL_N);

has c => (
  is => 'rw',
  required => 1,
  isa => 'Object',
);

sub resource {
  my($self, $id) = @_;

  $self -> resource_class -> new(
    c => $self -> c,
    source => $self -> c -> model($self -> resource_model) 
                         -> find({ uuid => $id })
  );
}

sub link {
  my($self) = @_;

  my $nom = $self -> resource_class;
  $nom =~ s/^.*:://;
  $nom = decamelize($nom);
  "".$self -> c -> uri_for('/' . $nom);
}

sub constrain_collection { $_[1] }

sub resources {
  my($self) = @_;

  my $c = $self -> c;
  my $resource_class = $self -> resource_class;
  my $q = $self -> c -> model($self -> resource_model);

  $q = $self -> constrain_collection($q);

  if(wantarray) {
    map { $resource_class -> new(c => $c, source => $_) } $q -> all;
  }
  elsif(defined wantarray) {
    $q -> count;
  }
}

sub resource_for_url {
  my($self, $url) = @_;

  my $uuid;
  if($url =~ m{^[-A-Za-z0-9_]{20}$}) {
    $uuid = $url;
  }
  else {
    my $url_base = $self -> link . "/";
    if(substr($url, 0, length($url_base), '') eq $url_base) {
      if($url =~ m{^[-A-Za-z0-9_]{20}$}) {
        $uuid = $url;
      }
    }
  }

  if($uuid) {
    $self -> resource($uuid);
  }
}

sub _GET {
  my $self = shift;

  if($self -> c -> request -> preferred_content_type =~ m{^application/rdf}) {
    my $rdf = RDF::Trine::Model->new(
      RDF::Trine::Store::DBI->temporary_store
    );
    $rdf -> begin_bulk_ops;
    $self -> GET_rdf($rdf, @_);
    $rdf -> end_bulk_ops;
    $rdf;
  }
  else {
    $self -> GET(@_);
  }
}

sub GET_rdf {
  my($self, $rdf, $deep) = @_;

  for my $resource ($self -> resources) {
    $resource -> GET_rdf($rdf);
  }
}

sub GET {
  my($self, $deep) = @_;

  my $json = {
    _links => { self => $self -> link },
  };

  my $items = [];

  for my $resource ($self -> resources) {
    push @{$items}, $resource -> GET;
  }

  $json -> {_embedded} = $items;

  $json;
}

sub _POST {
  my($self, $data) = @_;

  my $accepted = $self -> verify(POST => $data);

  $self -> POST($accepted);
}

sub verify {
  my($self, $method, $data) = @_;

  $data;
}

sub POST {
  my($self, $data) = @_;

  my $c = $self -> c;
  my $resource_class = $self -> resource_class;
  my $q = $self -> c -> model($self -> resource_model);

  my $new_resource = $self -> constrain_collection(
    $c -> model($self -> resource_model)
  ) -> new({});

  $new_resource -> insert;

  my $resource = $resource_class -> new(
    c => $c,
    source => $new_resource
  );

  $resource -> PUT($data);
}

1;
