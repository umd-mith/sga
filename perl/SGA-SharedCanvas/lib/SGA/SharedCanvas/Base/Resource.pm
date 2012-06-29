package SGA::SharedCanvas::Base::Resource;

use Moose;
use namespace::autoclean;

use Module::Load ();
use RDF::Trine;
use RDF::Query::Node::Blank;

has c => (
  is => 'rw',
  isa => 'Object',
  required => 1,
);

has source => (
  is => 'rw',
  isa => 'Object',
  required => 1,
);

has collection => (
  is => 'rw',
  isa => 'Maybe[Object]',
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
  isa => 'Str',
  lazy => 1,
  default => sub {
    my($self) = @_;

    my $class = blessed $self;
    $class =~ s{::Resource::}{::Collection::};
    $class;
  },
);

sub link {
  my($self) = @_;

  $self -> collection -> link . '/' . $self -> source -> uuid;
}

sub link_for {
  my($self, $sublink) = @_;

  $self -> link . '/' . $sublink;
}

sub _PUT {
  my($self, $json) = @_;

  # for now, we just won't understand rdf/json sent to us
  if($self -> c -> response -> content_type =~ m{^application/rdf}) { # if doing RDF
    # need to specify that we're using an unsupported media type for PUT
  }

  $self -> PUT($json);
}

sub _GET { 
  my $self = shift;

  if($self -> c -> request -> preferred_content_type =~ m{^application/rdf}) { # if doing RDF
    my $rdf = RDF::Trine::Model->new(
      RDF::Trine::Store::DBI->temporary_store
    );
    $rdf -> begin_bulk_ops;
    $self -> GET_rdf($rdf, @_);
    $rdf -> end_bulk_ops;
    $rdf;
  }
  else {
    $self -> GET(@_) 
  }
}

# used when we know we're trying to return RDF
sub GET_rdf {
  my($self, $rdf, $deep) = @_;


  my $meta = $self -> meta;

  my $link = $self -> link;

  my $rdf_types = $meta -> rdf_types;
  my $types = [];
  for my $t (@$rdf_types) {
    push @$types, { value => $t, type => 'uri' };
  }
  $rdf -> add_hashref({
    $link => {
      'http://www.w3.org/1999/02/22-rdf-syntax-ns#type' => $types,
    }
  });

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
    if(!ref $value) { # not an array
      $value = [ $value ];
    }

    for my $v (@$value) {
      push @$os, { value => $v, type => 'literal' };
    }

    my $type = $prop -> {rdf_type};
    if($type =~ m{:}) {
      for my $o (@$os) {
        $o -> {datatype} = $type;
      }
    }
    else { # things like 'uri'
      for my $o (@$os) {
        $o -> {type} = $type;
      }
    }

    $rdf -> add_hashref({
      $link => {
        $prop->{rdf_property} => $os
      }
    });
  }

  my @embedded = map { @{$self -> $_ || []} } $meta -> get_embedded_list;
  if(@embedded) {
    $rdf -> add_hashref({
      $link => {
        'http://www.w3.org/1999/02/22-rdf-syntax-ns#type' => [{
          type => 'uri',
          value => 'http://www.openarchives.org/ore/terms/Aggregation',
        }]
      }
    });
    for my $i (@embedded) {
      $rdf -> add_hashref({
        $link => {
          "http://www.openarchives.org/ore/terms/aggregates" => [{
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
    if(1 == scalar($meta->get_embedded_list) && 
       $meta -> embedded -> {($meta -> get_embedded_list)[0]}->{ordered}
         ) { # only one list here
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

sub GET {
  my($self, $deep) = @_;

  my $json = inner;
  $json = {} unless defined $json;

  if($self -> can("link")) {
    $json -> {_links} //= {};
    $json -> {_links} -> {self}  = $self -> link;
  }

  if($self -> collection) {
    $json -> {_links} //= {};
    $json -> {_links} -> {collection} = $self -> collection -> link;
  }

  my $meta = $self -> meta;

  for my $key ($meta -> get_owner_list) {
    my $bt = $self -> $key;
    if($bt && $bt -> can("link")) {
      $json -> {_links} //= {};
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
    $json -> {_embedded} //= {};
    $json -> {_embedded} -> {$key} //= [];
    my $hm = $self -> $key;
    $json -> {_links} -> {$key} = $self -> link_for($key);
    if($hm && @{$hm}) {
      for my $i (@{$hm}) {
        my $info = $i -> GET;
        if($deep) {
          push @{$json -> {_embedded}->{$key}}, $info;
        }
        else {
          push @{$json -> {_embedded}->{$key}}, +{ _links => $info->{_links}};
        }
      }
    }
  }

  return $json;
}

sub _DELETE { $_[0] -> DELETE }

sub DELETE { $_[0] -> source -> delete }

sub OPTIONS {
  my($self) = @_;

  #
  # we use media_formats to help build the list of acceptable types for
  # content negotiation
  #

  my %options = (
    methods => [qw/GET PUT OPTIONS DELETE/],
  );

  return \%options;
}

1;

__END__
