package SGA::SharedCanvas::Collection;

use Moose ();
use Moose::Exporter;
use Moose::Util::MetaRole;
use namespace::autoclean;

use String::CamelCase qw(decamelize);
use Lingua::EN::Inflect qw(PL_N);

use SGA::SharedCanvas::Base::ResourceCollection;
use SGA::SharedCanvas::Meta::ResourceCollection;

Moose::Exporter -> setup_import_methods(
  with_meta => [],
  as_is     => [],
  also      => 'Moose',
);

sub init_meta {
  shift;

  my %args = @_;

  Moose->init_meta(%args);

  Moose::Util::MetaRole::apply_metaroles(
     for             => $args{for_class},
     class_metaroles => {
       class => ['SGA::SharedCanvas::Meta::ResourceCollection'],
     }
  );

  my $meta = $args{for_class}->meta();

  $meta -> superclasses("SGA::SharedCanvas::Base::ResourceCollection");

  my $class = $args{for_class};
  $class =~ s{::Collection::}{::Resource::};

  $meta -> add_attribute( resource_class => (
    is => 'rw',
    isa => 'Str',
    default => $class,
  ) );

  $class =~ s{^.*::Resource::}{DB::};

  $meta -> add_attribute( resource_model => (
    is => 'rw',
    isa => 'Str',
    default => $class
  ) );

  $class =~ s{^.*::}{};
  $class = decamelize($class);
  $class = join("_", split(/\s/, PL_N(join(" ", split(/_/, $class)))));

  $meta -> add_attribute( resource_name => (
    is => 'rw',
    isa => 'Str',
    default => $class
  ) );

  return $meta;
}

1;
