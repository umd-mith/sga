package SGA::SharedCanvas::Meta::Resource;

use Moose::Role;
use namespace::autoclean;

use Data::UUID;
use Data::Verifier;

has properties => (
  is => 'rw',
  isa => 'HashRef',
  default => sub { +{ } },
  lazy => 1,
);

has owners => (
  is => 'rw',
  isa => 'HashRef',
  default => sub { +{ } },
  lazy => 1,
);

has embedded => (
  is => 'rw',
  isa => 'HashRef',
  default => sub { +{ } },
  lazy => 1,
);

has embedded_in => (
  is => 'rw',
  isa => 'HashRef',
  default => sub { +{ } },
  lazy => 1,
);


has schema => (
  is => 'rw',
  isa => 'HashRef',
  lazy => 1,
  builder => '_build_schema',
);

has contains => (
  is => 'rw',
  isa => 'HashRef',
  default => sub { +{ } },
  lazy => 1,
);

has nested => (
  is => 'rw',
  isa => 'HashRef',
  default => sub { +{ } },
  lazy => 1,
);

has verifier => (
  is => 'ro',
  isa => 'HashRef',
  lazy => 1,
  builder => '_build_verifiers',
);

has rdf_types => (
  is => 'rw',
  isa => 'ArrayRef',
  default => sub{ [ ] },
  lazy => 1,
);

has media_formats => (
  is => 'rw',
  isa => 'ArrayRef',
  default => sub{ [ ] },
  lazy => 1,
);

sub add_prop {
  my($self, $key, %config) = @_;

  if(substr($key, 0, 1) eq '+') {
    $key = substr($key, 1);
    $self -> properties -> {$key} //= {};
    for my $k (keys %config) {
      $self -> properties -> {$key} -> {$k} = $config{$k};
    }
  }
  elsif($self -> properties->{$key}) {
    # should be an error
  }
  else {
    $self -> properties -> {$key} = \%config;
  }

  my $method = $config{source} || sub { $_[0] -> source -> $key };
  $self -> add_method( $key => $method );
}

sub get_prop_list { keys %{$_[0] -> properties} }

sub get_prop {
  my($self, $k) = @_;

  $self -> properties -> {$k};
}

sub add_hasa {
  my($self, $key, %config) = @_;

  my $resource_class = $config{isa};
  my $method = $config{source};
  $self -> add_method( $key => sub {
    my($self) = @_;
    my $row = $self->$method();
    if($row) {
      return $resource_class -> new( c => $self->c, source => $row );
    }
  } );

  $self -> contains -> {$key} = \%config;
}

sub get_hasa_list { keys %{$_[0]->contains} }

sub get_hasa { $_[0] -> contains -> {$_[1]} }

sub add_owner {
  my($self, $key, %config) = @_;

  my $resource_class = $config{isa};
  my $method = $config{source};
  $self -> add_method( $key => sub {
    my($self) = @_;
    my $row = $self->$method();
    if($row) {
      return $resource_class -> new( c => $self->c, source => $row );
    }
  } );

  $self -> owners -> {$key} = \%config;
}

sub get_owner_list { keys %{$_[0]->owners} }

sub has_owner { defined $_[0]->owners->{$_[1]} }

sub get_owner { $_[0] -> owners -> { $_[1] } }

sub add_nested {
  my($self, $key, %config) = @_;

  my $resource_class = $config{isa};
  Module::Load::load($resource_class);
  my $method = $config{source};
  $self -> add_attribute( $key => (
    lazy => 1,
    is => 'ro',
    default => sub {
      my($self) = @_;
      $resource_class -> new( c => $self -> c, source => $self->$method() );
    } 
  ) );
}

sub get_nested_list { keys %{$_[0]->nested} }

sub get_nested { $_[0] -> nested -> {$_[1]} }

sub add_embedded {
  my($self, $key, %config) = @_;

  my $resource_class = $config{isa};
  Module::Load::load($resource_class);
  my $method = $config{source};
  $self -> add_method( $key => sub {
    my($self) = @_;
    [
      grep { defined } map {
        $_ ? $resource_class -> new( c => $self -> c, source => $_ )
           : undef
      } $self->$method()
    ];
  } );

  $self -> embedded -> {$key} = \%config;
}

sub get_embedded_list { keys %{$_[0]->embedded} }

sub has_embedded { defined $_[0]->embedded->{$_[1]} }

sub get_embedded { $_[0] -> embedded -> { $_[1] } }

sub add_embedded_in {
  my($self, $key, %config) = @_;

  my $resource_class = $config{isa};
  Module::Load::load($resource_class);
  my $method = $config{source};
  $self -> add_method( $key => sub {
    my($self) = @_;
    [
      grep { defined } map {
        $_ ? $resource_class -> new( c => $self -> c, source => $_ )
           : undef
      } $self->$method()
    ];
  } );

  $self -> embedded_in -> {$key} = \%config;
}

sub get_embedded_in_list { keys %{$_[0]->embedded_in} }

sub has_embedded_in { defined $_[0]->embedded_in->{$_[1]} }

sub get_embedded_in { $_[0] -> embedded_in -> { $_[1] } }

sub add_rdf_type {
  my($self, $url) = @_;

  push @{$self -> rdf_types}, $url;
}

sub add_media_format {
  my($self, $format) = @_;

  push @{$self -> media_formats}, $format;
}

my $ug = Data::UUID -> new;

sub create_uuid { $ug -> create_string }

sub _build_schema {
  my($self) = @_;

  my $schema = {};

  for my $prop ($self -> get_prop_list) {
    my $info = $self -> get_prop($prop);
    $schema -> {properties} -> {$prop} -> {source} = $info -> {maps_to} || $prop;
    $schema -> {properties} -> {$prop} -> {is} = $info -> {is} || 'rw';
    $schema -> {properties} -> {$prop} -> {valueType} = $info -> {value_type} || 'text';
    $schema -> {properties} -> {$prop} -> {required} = 1 if $info -> {required};
  }

  for my $key ($self -> get_embedded_list) {
    $schema -> {embedded} -> {$key} = {};
  }

  for my $key ($self -> get_owner_list) {
    my $info = $self -> get_owner($key);
    $schema -> {belongs_to} -> {$key} = {
      source => $info -> {maps_to} || $key,
      is => $info->{is} || 'ro',
    };
    if($info->{value_type}) {
      $schema -> {belongs_to} -> {$key} -> {valueType} = $info->{value_type};
    }
  }

  for my $key ($self -> get_hasa_list) {
    my $info = $self -> get_hasa($key);
    $schema -> {properties} -> {$key} -> {source} = $info -> {maps_to} || $key;
    $schema -> {properties} -> {$key} -> {is} = $info -> {is} || 'ro';
    $schema -> {properties} -> {$key} -> {valueType} = $info->{valueType} || 'link';
    $schema -> {properties} -> {$key} -> {required} = 1 if $info -> {required};
  }

  $schema;
}

sub _build_verifiers {
  my($self) = @_;

  my %profiles = ( POST => {}, PUT => {} );

  for my $k (keys %{$self -> properties}) {
    my $p = $self -> properties -> {$k};
    next if defined($p->{is}) && $p->{is} eq 'ro';
    next if defined($p->{verifier});

    $profiles{POST}{$k} = {};
    $profiles{PUT }{$k} = {};

    for my $kk (qw/type filters max_length min_length dependent/) {
      if(defined $p->{$kk}) {
        $profiles{POST}{$k}{$kk} = $profiles{PUT }{$k}{$kk} = $p->{$kk};
      }
    }
    for my $kk(qw/required/) {
      $profiles{POST}{$k}{$kk} = $p->{$kk} if defined $p->{$kk};
    }
  }

  return {
    POST => Data::Verifier -> new(profile => $profiles{POST}),
    PUT  => Data::Verifier -> new(profile => $profiles{PUT }),
  };
}

1;

__END__
