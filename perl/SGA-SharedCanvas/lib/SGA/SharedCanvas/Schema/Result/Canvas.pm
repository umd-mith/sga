use utf8;
package SGA::SharedCanvas::Schema::Result::Canvas;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

SGA::SharedCanvas::Schema::Result::Canvas

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<canvas>

=cut

__PACKAGE__->table("canvas");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 uuid

  data_type: 'char'
  is_nullable: 0
  size: 20

=head2 label

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=head2 height

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 width

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "uuid",
  { data_type => "char", is_nullable => 0, size => 20 },
  "label",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
  "height",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "width",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2012-06-27 13:59:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:5LXQN1Y2p+VxSEiSdhDucQ

with 'SGA::SharedCanvas::Role::Schema::Result::UUID';

__PACKAGE__->has_many('canvas_sequence' => 'SGA::SharedCanvas::Schema::Result::CanvasSequence', 'canvas_id');
__PACKAGE__->many_to_many('sequences' => 'canvas_sequence', 'sequence');

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
