package SGA::SharedCanvas::Meta::Resource;

use Moose::Role;
use namespace::autoclean;

use Data::UUID;

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
}

sub get_prop_list { keys %{$_[0] -> properties} }

sub get_prop {
  my($self, $k) = @_;

  $self -> properties -> {$k};
}

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

1;

__END__
