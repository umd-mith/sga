package SGA::SharedCanvas::Resource;

use Moose ();
use Moose::Exporter;
use Moose::Util::MetaRole;

use SGA::SharedCanvas::Base::Resource;
use SGA::SharedCanvas::Meta::Resource;

use namespace::autoclean;

Moose::Exporter->setup_import_methods(
  with_meta => [ 'prop', 'has_many', 'belongs_to', 'rdf_type', 'media_format', 'has_a', 'contains_a', 'belongs_to_many' ],
  as_is     => [ ],
  also      => 'Moose',
);

sub init_meta {
  shift;
  my %args = @_;

  Moose->init_meta(%args);

  Moose::Util::MetaRole::apply_metaroles(
     for             => $args{for_class},
     class_metaroles => {
       class => ['SGA::SharedCanvas::Meta::Resource'],
     }
  );

  my $meta = $args{for_class}->meta();

  $meta -> superclasses("SGA::SharedCanvas::Base::Resource");

  return $meta;
}

sub prop {
  my($meta, $name, %props) = @_;

  $meta -> add_prop( $name, %props );
}

sub media_format {
  my($meta, $format) = @_;

  $meta -> add_media_format( $format );
}

sub rdf_type {
  my($meta, $url) = @_;

  $meta -> add_rdf_type($url);
}

sub belongs_to {
  my($meta, $key, $resource_class, %config) = @_;

  my $method;

  if(!$config{source}) {
    $method = sub { $_[0] -> source -> $key };
  }
  elsif(!ref $config{source}) {
    my $mkey = $config{source};
    $method = sub { $_[0] -> source -> $mkey };
  }
  else {
    $method = $config{source};
  }

  $meta -> add_owner( $key,
    %config,
    isa => $resource_class,
    source => $method,
  );
}

sub belongs_to_many {
  my($meta, $key, $resource_class, %config) = @_;

  my $method;

  if(!$config{source}) {
    $method = sub { $_[0] -> source -> $key };
  }
  elsif(!ref $config{source}) {
    my $mkey = $config{source};
    $method = sub { $_[0] -> source -> $mkey };
  }
  else {
    $method = $config{source};
  }

  $meta -> add_embedded_in( $key, (
    %config,
    isa => $resource_class,
    source => $method,
  ));
}

sub has_many {
  my($meta, $key, $resource_class, %config) = @_;

  my $method;

  if(!$config{source}) {
    $method = sub { $_[0] -> source -> $key };
  }
  elsif(!ref $config{source}) {
    my $mkey = $config{source};
    $method = sub { $_[0] -> source -> $mkey };
  }
  else {
    $method = $config{source};
  }

  $meta -> add_embedded( $key, (
    %config,
    isa => $resource_class,
    source => $method,
  ));
}

sub has_a {
  my($meta, $key, $resource_class, %config) = @_;

  my $method;

  if(!$config{source}) {
    $method = sub { $_[0] -> source -> $key };
  }
  elsif(!ref $config{source}) {
    my $mkey = $config{source};
    $method = sub { $_[0] -> source -> $mkey };
  }
  else {
    $method = $config{source};
  }

  $meta -> add_hasa( $key, (
    %config,
    isa => $resource_class,
    source => $method,
  ) );
}

#
# used to point to another resource to handle part of the source associated
# with the current resource
#
# Allows nested JSON to handle part of the current object.
#
sub contains_a {
  my($meta, $key, $resource_class, %config) = @_;

  my $method;
  if(!$config{source}) {
    $method = sub { $_[0] -> source };
  }
  elsif(!ref $config{source}) {
    my $mkey = $config{source};
    $method = sub { $_[0] -> source -> $mkey };
  }
  else {
    $method = $config{source};
  }

  $meta -> add_nested( $key, (
    %config,
    isa => $resource_class,
    source => $method,
  ));
}

1;

__END__
