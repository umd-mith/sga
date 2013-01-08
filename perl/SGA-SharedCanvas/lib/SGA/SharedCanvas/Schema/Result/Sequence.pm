use utf8;
package SGA::SharedCanvas::Schema::Result::Sequence;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

SGA::SharedCanvas::Schema::Result::Sequence

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

=head1 TABLE: C<sequence>

=cut

__PACKAGE__->table("sequence");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 uuid

  data_type: 'char'
  is_nullable: 0
  size: 20

=head2 updated_at

  data_type: 'datetime'
  is_nullable: 0

=head2 label

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "uuid",
  { data_type => "char", is_nullable => 0, size => 20 },
  "updated_at",
  { data_type => "datetime", is_nullable => 0 },
  "label",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2012-07-13 09:22:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:0ZUcZXRwIPxfTPE426ygmw

with 'SGA::SharedCanvas::Role::Schema::Result::UUID';
with 'SGA::SharedCanvas::Role::Schema::Result::Timestamps';

__PACKAGE__->has_many('manifest_sequence' => 'SGA::SharedCanvas::Schema::Result::ManifestSequence', 'sequence_id');
__PACKAGE__->many_to_many('manifests' => 'manifest_sequence', 'manifest');

__PACKAGE__->has_many('canvas_sequence' => 'SGA::SharedCanvas::Schema::Result::CanvasSequence', 'sequence_id', { order_by => \'position' });
__PACKAGE__->many_to_many('canvases' => 'canvas_sequence', 'canvas');

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
