use CatalystX::Declare;

class SGA::SharedCanvas::Base::ResourceCollection {

  use String::CamelCase qw(decamelize);
  use Lingua::EN::Inflect qw(PL_N);

  has c => (
    is => 'rw',
    required => 1,
    isa => 'Object',
  );

  method resource ($id) {
    my $source = $self -> c -> model($self -> resource_model)
                            -> find({ uuid => $id });
    if($source) {
      $self -> resource_class -> new(
        c => $self -> c,
        source => $source,
      );
    }
  }

  method link {
    my $nom = $self -> resource_class;
    $nom =~ s/^.*:://;
    $nom = decamelize($nom);
    "".$self -> c -> uri_for('/' . $nom);
  }

  method schema {
    $self -> resource_class -> new(c => $self -> c) -> schema;
  }

  method constrain_collection ($q) { $q }

  method resources {
    my $ctx = $self -> c;
    my $resource_class = $self -> resource_class;
    my $q = $self -> c -> model($self -> resource_model);

    $q = $self -> constrain_collection($q);

    if(wantarray) {
      map { $resource_class -> new(c => $ctx, source => $_) } $q -> all;
    }
    elsif(defined wantarray) {
      $q -> count;
    }
  }

  method resource_for_url ($url) {
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

  method _GET ($deep = 0) {
    my $wanted_type = $self -> c -> request -> preferred_content_type;
    if($wanted_type =~ m{^application/rdf} || $wanted_type eq 'text/turtle') {
      my $rdf = RDF::Trine::Model->new(
        RDF::Trine::Store::DBI->temporary_store
      );
      $rdf -> begin_bulk_ops;
      $self -> GET_rdf($rdf, $deep);
      $rdf -> end_bulk_ops;
      $rdf;
    }
    elsif($wanted_type =~ m{^image/}) {
      $self -> GET_image($deep);
    }
    else {
      $self -> GET($deep);
    }
  }

  method GET_rdf ($rdf, $deep = 0) {
    for my $resource ($self -> resources) {
      $resource -> GET_rdf($rdf);
    }
  }

  method GET ($deep = 0) {
    my $json = {
      _links => { self => $self -> link },
      _schema => $self -> schema,
    };

    my $items = [];

    for my $resource ($self -> resources) {
      push @{$items}, $resource -> GET;
    }

    $json -> {_embedded} = $items;

    $json;
  }

  method _POST ($data) {
    my $wanted_type = $self -> c -> request -> preferred_content_type;
    # if $wanted_type is in our list of media types, then we support
    # raw files of those types
    my $allowed_media_types = $self -> resource_class -> meta -> media_formats;
    if(grep { $_ eq $wanted_type } @{$allowed_media_types}) {
      $self -> POST_raw($data->{file});
    }
    else {
      my $accepted = $self -> verify(POST => $data);
      $self -> POST($accepted);
    }
  }

  method verify ($method, $data) {
    $data;
  }

  method POST ($data) {
    my $ctx = $self -> c;
    my $resource_class = $self -> resource_class;
    my $q = $self -> c -> model($self -> resource_model);

    my $new_resource = $self -> constrain_collection(
      $ctx -> model($self -> resource_model)
    ) -> new({});

    my $resource = $resource_class -> new(
      c => $ctx,
      source => $new_resource
    );

    $resource -> _PUT($data);
  }
}
