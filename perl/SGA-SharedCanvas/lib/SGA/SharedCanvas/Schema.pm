use utf8;
package SGA::SharedCanvas::Schema;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use Moose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2012-06-27 11:23:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:PjAZm5Lvp+U5UXyLUaZ0CQ

after connection => sub {
  my($self) = @_;

  # If we're SQLite and dbname = :memory:, then deploy
  my $dsn = $self -> storage -> connect_info;
  while(ref $dsn) {
    if(ref $dsn eq 'HASH') {
      $dsn = $dsn->{dsn};
    }
    elsif(ref $dsn eq 'ARRAY') {
      $dsn = $dsn->[0];
    }
    else {
      $dsn = undef;
    }
  }
  if($dsn eq 'dbi:SQLite:dbname=:memory:') {
    $self -> deploy;
  }
};


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
