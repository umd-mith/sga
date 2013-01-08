use utf8;
package SGA::SharedCanvas::Schema::Result::LayerManifest;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

SGA::SharedCanvas::Schema::Result::LayerManifest

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

=head1 TABLE: C<layer_manifest>

=cut

__PACKAGE__->table("layer_manifest");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 layer_id

  data_type: 'integer'
  is_nullable: 0

=head2 manifest_id

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "layer_id",
  { data_type => "integer", is_nullable => 0 },
  "manifest_id",
  { data_type => "integer", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2012-08-10 09:55:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ol+5GFDe5w50moIvYIDMEw

__PACKAGE__->belongs_to(layer => 'SGA::SharedCanvas::Schema::Result::Layer', 'layer_id');
__PACKAGE__->belongs_to(manifest => 'SGA::SharedCanvas::Schema::Result::Manifest', 'manifest_id');

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
