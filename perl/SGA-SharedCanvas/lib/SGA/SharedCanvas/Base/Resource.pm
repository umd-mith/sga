use MooseX::Declare;

class SGA::SharedCanvas::Base::Resource {

  use SGA::SharedCanvas::Exception;
  use SGA::SharedCanvas::Types qw( Context Collection );
  use MooseX::Types::Moose qw( Maybe Object ClassName );

  use Module::Load ();
  use RDF::Trine;
  use RDF::Query::Node::Blank;

  use Lingua::EN::Inflect qw(PL_V);
  use String::CamelCase qw(decamelize);

  has c => (
    is => 'rw',
    isa => Context,
    required => 1,
  );

  has source => (
    is => 'rw',
    isa => Object,
  );

  has collection => (
    is => 'rw',
    isa => Collection,
    lazy => 1,
    default => sub {
      my($self) = @_;
      my $class = $self -> resource_collection_class;
      eval {
        Module::Load::load($class);
        $self -> resource_collection_class -> new(
          c => $self -> c
        );
      };
    },
  );

  has resource_collection_class => (
    is => 'rw',
    isa => ClassName,
    lazy => 1,
    default => sub {
      my($self) = @_;
  
      my $class = blessed $self;
      $class =~ s{::Resource::}{::Collection::};
      $class;
    },
  );

  method link {
    if($self -> source) {
      $self -> collection -> link . '/' . $self -> source -> uuid;
    }
    else {
      my $nom = $self -> meta -> {package};
      $nom =~ s{^.*::}{};
      $nom = decamelize($nom);
      $self -> collection -> link . '/{?' . $nom . '_id}';
    }
  }

  method link_for ($for) {
    if($for eq 'root') { return $self -> c -> uri_for('/'); }

    my $class = blessed $self;
    my $meta = $self -> meta;

    if($meta -> has_embedded($for)) {
      my $frag = $meta -> get_embedded($for) -> {link_fragment} || PL_V($for);
      return $self -> link . '/' . $frag;
    }
    if($meta -> has_owner($for)) {
      return $self -> $for -> link;
    }
  }

  method schema {
    my $schema = $self -> meta -> schema;

    for my $k (keys %{$schema -> {embedded}}) {
      $schema -> {embedded} -> {$k} -> {_links} -> {self} =
        $self -> link_for($k);
    }

    $schema;
  }

  method _PUT($json) {
    my $wanted_type = $self -> c -> request -> preferred_content_type;
    my $allowed_media_types = $self -> meta -> media_formats;
    if(grep { $_ eq $wanted_type } @{$allowed_media_types}) {
      return $self -> PUT_raw($json);
    }
    elsif($wanted_type =~ m{^application/rdf} || $wanted_type eq 'text/turtle') {
      # need to specify that we're using an unsupported media type for PUT
      # for now, at least
      die "Unsupported media type";
    }

    my $embeddings = delete $json->{_embedded};

    my $nested = {};
    for my $n ($self -> meta -> get_nested_list) {
      $nested->{$n} = delete $json -> {$n};
    }

    my $hasa = {};

    for my $h ($self -> meta -> get_hasa_list) {
      my $hinfo = $self -> meta -> get_hasa($h);
      next if defined($hinfo->{is}) && $hinfo->{is} eq 'ro';
      my $r = delete $json -> {$h};
      my $collection = $hinfo -> {isa} -> new(c => $self -> c) -> collection;
      $r = $collection -> resource_for_url($r);
      if($r) {
        $hasa->{$h . "_id"} = $r -> source -> id;
      }
      if($hinfo->{required} && !$hasa->{$h}) {
        # TODO: die with an error about requiring a value
      }
    }

    my $verifier = $self -> meta -> verifier -> {PUT};
    if($verifier) {
      print STDERR "Verifying simple data\n";
      my $results = $verifier -> verify($json);
      if(!$results -> success) {
        # TODO: die with an error
      }
      my %values = $results -> valid_values;
      delete @values{grep { !defined $values{$_} } keys %values};
      $json = \%values;
    }

    for my $h (keys %$hasa) {
      $json->{$h} = $hasa->{$h};
    }

    # now make sure embeddings are writable
    # and then figure out what objects they are
    my $verified_embeddings = {};

    for my $name (keys %{$embeddings || {}}) {
      my $einfo = $self -> meta -> get_embedded($name);
      next if $einfo->{is} && $einfo->{is} eq 'ro';

      my $collection = $einfo -> {isa} -> new(c => $self -> c) -> collection;
      $verified_embeddings->{$name} = [
        grep { defined }
        map { $_ -> source }
        grep { defined }
        map { $collection -> resource_for_url($_) }
          @{$embeddings->{$name} || []}
      ];
    }

    $json -> {_embedded} = $verified_embeddings;
    $json -> {_nested} = $nested;
    $self -> PUT($json);
  }

  method PUT ($json) {
    my $embedded = delete $json -> {_embedded};
    my $nested = delete $json -> {_nested};

    $self -> source -> set_inflated_columns($json);

    for my $n (keys %$nested) {
      my $ninfo = $self -> meta -> get_nesting($n);
      next if defined($ninfo->{is}) && $ninfo->{is} eq 'ro';

      my $r = $self -> $n; # get resource object for this nesting
      if($r) {
        $r -> PUT($nested->{$n});
      }
    }

    $self -> source -> update_or_insert;

    for my $name (keys %{$embedded || {}}) {
      my $einfo = $self -> meta -> get_embedded($name);
      $self -> put_list($name, $embedded->{$name}, $einfo->{ordered});
    }
    $self;
  }

  method put_list ($list_name, $list, $ordered = 0) {
    my $own_table = $self -> source -> result_source -> name;
    my $list_info = $self -> meta -> get_embedded($list_name);
    my $target_collection = $list_info -> {isa} -> new(c => $self -> c) -> collection;
    my $target_table = $self -> c -> model($target_collection -> resource_model) -> result_source -> name;
  
    my $relationship = join "_", sort ($own_table, $target_table);

    my(%orig) = (
      map { ($_ -> $target_table -> uuid) => $_ } 
          $self -> source -> $relationship
    );

    my $i = 0;
    for my $thing (@{$list||[]}) {
      print STDERR "putting ", $thing -> id, " in list\n";
      if($orig{$thing->uuid}) {
        print STDERR "    already in list... moving on to next\n";
        $orig{$thing->uuid}->move_to($i) if $ordered;
        delete $orig{$thing -> uuid};
      }
      else {
        print STDERR "Adding it to the list\n";
        if($ordered) {
          $self -> source -> $relationship -> new({
            $own_table . "_id" => $self -> source -> id,
            $target_table . "_id" => $thing -> id,
            position => $i
          }) -> insert;
        }
        else {
          print STDERR "Adding $relationship [", $self->source->id, ", ", $thing -> id, "]\n";
          $self -> source -> $relationship -> new({
            $own_table . "_id" => $self -> source -> id,
            $target_table . "_id" => $thing -> id
          }) -> insert;
        }
      }
      $i += 1;
    }

    for my $ms (values %orig) {
      $ms -> delete;
    }
  }

  method _GET ($deep = 0) {
    my $wanted_type = $self -> c -> request -> preferred_content_type;
    my $allowed_media_types = $self -> meta -> media_formats;
    if(grep { $_ eq $wanted_type } @{$allowed_media_types}) {
      my $json = $self -> GET_raw;
      $json->{type} = $wanted_type;
      $json;
    }
    elsif($wanted_type =~ m{^application/rdf} || $wanted_type eq 'text/turtle') { # if doing RDF
      my $rdf = RDF::Trine::Model->new(
        RDF::Trine::Store::DBI->temporary_store
      );
      $rdf -> begin_bulk_ops;
      $self -> GET_rdf($rdf, @_);
      $rdf -> end_bulk_ops;
      $rdf;
    }
    else {
      $self -> GET($deep) 
    }
  }

  # used when we know we're trying to return RDF
  method GET_rdf ($rdf, $deep = 0) {
    my $meta = $self -> meta;

    my $link = $self -> link;

    my $rdf_types = $meta -> rdf_types;
    my $types = [];
    for my $t (@$rdf_types) {
      if($deep || $t ne 'http://www.openarchives.org/ore/terms/ResourceMap') {
        push @$types, { value => $t, type => 'uri' };
      }
    }
    $rdf -> add_hashref({
      $link => {
        'http://www.w3.org/1999/02/22-rdf-syntax-ns#type' => $types,
      }
    });

    if($deep && grep { "http://www.openarchives.org/ore/terms/ResourceMap" eq $_ } @$rdf_types) {
      $rdf -> add_hashref({
        $link => {
          'http://www.openarchives.org/ore/terms/describes' => [{
            value => $link,
            type => 'uri'
          }],
        },
      });
    }

    my %props;

    for my $key ($meta -> get_prop_list) {
      my $prop = $meta -> get_prop($key);
      next if $prop->{deep} && !$deep;
      next unless $prop -> {rdf_property};

      my $os = [];

      my $value;
      if($prop->{source}) {
        $value = $prop->{source} -> ($self);
      }
      elsif($prop->{method}) {
        my $method = $prop->{method};
        $value = $self -> source -> $method;
      }
      else {
        $value = $self -> source -> $key;
      }
      next if !defined $value;

      if(!ref $value) { # not an array
        next if $value eq "";
        $value = [ $value ];
      }

      for my $v (@$value) {
        push @$os, { value => $v, type => 'literal' };
      }

      my $type = $prop -> {rdf_type};
      if(defined($type) && $type =~ m{:}) {
        for my $o (@$os) {
          $o -> {datatype} = $type;
        }
      }
      elsif(defined($type)) { # things like 'uri'
        for my $o (@$os) {
          $o -> {type} = $type;
        }
      }

      if($prop -> {rdf_datatype}) {
        for my $o (@$os) {
          $o -> {datatype} = $prop -> {rdf_datatype};
        }
      }

      $rdf -> add_hashref({
        $link => {
          $prop->{rdf_property} => $os
        }
      });
    }

    for my $key ($meta -> get_hasa_list) {
      my $hasa = $meta -> get_hasa($key);
      my $item = $self -> $key;
      my $predicate = $hasa -> {predicate} ||
                      "http://www.openarchives.org/ore/terms/aggregates";
      if($predicate eq 'http://www.openarchives.org/ore/terms/aggregates') {
        $rdf -> add_hashref({
          $link => {
            'http://www.w3.org/1999/02/22-rdf-syntax-ns#type' => [{
              type => 'uri',
              value => 'http://www.openarchives.org/ore/terms/Aggregation',
            }]
          }
        });
      }
      $rdf -> add_hashref({
        $link => {
          $predicate => [{
            type => 'uri',
            value => $item -> link,
          }]
        }
      });
      if($deep) {
        $item -> GET_rdf($rdf);
      }
      else {
        # this should make the viewer retrieve the URL to get more info
        $rdf -> add_hashref({
          $item -> link => {
            "http://www.openarchives.org/ore/terms/isDescribedBy" => [{
              type => 'uri',
              value => $item -> link,
            }],
          },
        });
      }
    }

    my @embedded; # = map { @{$self -> $_ || []} } $meta -> get_embedded_list;
    for my $embed_key ($meta -> get_embedded_list) {
      my $predicate = $meta -> embedded -> {$embed_key} -> {predicate} ||
                      "http://www.openarchives.org/ore/terms/aggregates";
      my @items = @{$self -> $embed_key || []};
      if($predicate eq 'http://www.openarchives.org/ore/terms/aggregates') {
        if($meta -> embedded -> {$embed_key} -> {ordered}) {
          push @embedded, @items;
        }
        $rdf -> add_hashref({
          $link => {
            'http://www.w3.org/1999/02/22-rdf-syntax-ns#type' => [{
              type => 'uri',
              value => 'http://www.openarchives.org/ore/terms/Aggregation',
            }]
          }
        });
      }
      for my $i (@items) {
        $rdf -> add_hashref({
          $link => {
            $predicate => [{
              type => 'uri',
              value => $i -> link
            }]
          }
        });
        if($deep) {
          $i -> GET_rdf($rdf);
        }
        else {
          $rdf -> add_hashref({
            $i -> link => {
              "http://www.openarchives.org/ore/terms/isDescribedBy" => [{
                type => 'uri',
                value => $i -> link
              }]
            }
          });
        }
      }
      if(@embedded && 
         1 == grep { $meta -> embedded -> {$_} -> {ordered} } $meta->get_embedded_list
        ) {
        my @links = map { RDF::Trine::Node::Resource->new($_ -> link) } @embedded;
        my $first = shift @links;
        my $rest = $rdf -> add_list(@links);
        $rdf -> add_hashref({
          $link => {
            'http://www.w3.org/1999/02/22-rdf-syntax-ns#type' => [{
              type => 'uri',
              value => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#List'
            }],
            'http://www.w3.org/1999/02/22-rdf-syntax-ns#first' => [{
              type => 'uri',
              value => $first->uri
            }],
            'http://www.w3.org/1999/02/22-rdf-syntax-ns#rest' => [{
              type => $rest -> is_blank    ? 'blank'
                    : $rest -> is_resource ? 'uri'
                    : $rest -> is_literal  ? 'literal'
                    : $rest -> is_nil      ? 'uri'
                    : 'literal'
                    ,
              value => $rest -> as_string
            }],
          }
        });
      }
    }
  }

  method GET ($deep = 0) {
    my $json = inner || {};

    if($self -> can("link")) {
      $json -> {_links} -> {self}  = $self -> link;
    }

    if($self -> collection) {
      $json -> {_links} -> {collection} = $self -> collection -> link;
    }

    my $meta = $self -> meta;

    for my $key ($meta -> get_owner_list) {
      my $bt = $self -> $key;
      if($bt && $bt -> can("link")) {
        $json -> {_links} -> {$key} = $bt -> link;
      }
    }

    for my $key ($meta -> get_prop_list) {
      my $prop = $meta -> get_prop($key);
      next if $prop->{deep} && !$deep;
      my $value;
      if($prop->{source}) {
        $value = $prop->{source} -> ($self);
      }
      elsif($prop->{method}) {
        my $method = $prop->{method};
        $value = $self -> source -> $method;
      }
      else {
        $value = $self -> source -> $key;
      }
      $json -> {$key} = $value;
    }

    for my $key ($meta -> get_embedded_list) {
      $json -> {_embedded} -> {$key} //= [];
      my $hm = $self -> $key;
      $json -> {_links} -> {$key} = $self -> link_for($key);
      if($hm && @{$hm}) {
        for my $i (@{$hm}) {
          if($deep) {
            my $info = $i -> GET;
            push @{$json -> {_embedded}->{$key}}, $info;
          }
          else {
            push @{$json -> {_embedded}->{$key}}, $i -> link;
          }
        }
      }
    }

    return $json;
  }

  method _DELETE { $self -> DELETE; }

  method DELETE { $self -> source -> delete; }

  method OPTIONS {
    #
    # we use media_formats to help build the list of acceptable types for
    # content negotiation
    #

    my %options = (
      methods => [qw/GET PUT OPTIONS DELETE/],
    );

    return \%options;
  }
}
