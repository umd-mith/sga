package SGA::SharedCanvas::Types;

use MooseX::Types -declare => [
  qw(
    Resource
    Collection
    Context
  )
];

use MooseX::Types::Moose qw/Object/;

subtype Resource,
  as Object,
  where {
    print STDERR "Superclasses of $_:\n";
    print STDERR "  ".join("\n  ", $_ -> meta -> linearized_isa), "\n";
    1;
  },
;

subtype Collection,
  as Object,
  where { $_ -> isa('SGA::SharedCanvas::Base::ResourceCollection') },
;

subtype Context,
  as Object,
  where { $_ -> isa('SGA::SharedCanvas') },
;

1;
