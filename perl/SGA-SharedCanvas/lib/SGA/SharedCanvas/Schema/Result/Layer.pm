use utf8;
package SGA::SharedCanvas::Schema::Result::Layer;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

SGA::SharedCanvas::Schema::Result::Layer

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

=head1 TABLE: C<layer>

=cut

__PACKAGE__->table("layer");

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

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "uuid",
  { data_type => "char", is_nullable => 0, size => 20 },
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
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Mp8TV0z/Rnfc8O9wCaCGuQ

with 'SGA::SharedCanvas::Role::Schema::Result::UUID';

__PACKAGE__ -> has_many('layer_manifest' => 'SGA::SharedCanvas::Schema::Result::LayerManifest', 'layer_id');
__PACKAGE__ -> many_to_many('manifests' => 'layer_manifest', 'manifest');

__PACKAGE__ -> has_many('layer_text_annotation_list' => 'SGA::SharedCanvas::Schema::Result::LayerTextAnnotationList', 'layer_id');
__PACKAGE__ -> many_to_many('text_annotation_lists' => 'layer_text_annotation_list', 'text_annotation_list');

__PACKAGE__ -> has_many('image_annotation_list_layer' => 'SGA::SharedCanvas::Schema::Result::ImageAnnotationListLayer', 'layer_id');
__PACKAGE__ -> many_to_many('image_annotation_lists' => 'image_annotation_list_layer', 'image_annotation_list');

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
