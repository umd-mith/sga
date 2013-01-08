use utf8;
package SGA::SharedCanvas::Schema::Result::CanvasZoneAnnotation;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

SGA::SharedCanvas::Schema::Result::CanvasZoneAnnotation

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

=head1 TABLE: C<canvas_zone_annotation>

=cut

__PACKAGE__->table("canvas_zone_annotation");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 zone_annotation_id

  data_type: 'integer'
  is_nullable: 0

=head2 canvas_id

  data_type: 'integer'
  is_nullable: 0

=head2 x

  data_type: 'integer'
  is_nullable: 0

=head2 y

  data_type: 'integer'
  is_nullable: 0

=head2 w

  data_type: 'integer'
  is_nullable: 0

=head2 h

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "zone_annotation_id",
  { data_type => "integer", is_nullable => 0 },
  "canvas_id",
  { data_type => "integer", is_nullable => 0 },
  "x",
  { data_type => "integer", is_nullable => 0 },
  "y",
  { data_type => "integer", is_nullable => 0 },
  "w",
  { data_type => "integer", is_nullable => 0 },
  "h",
  { data_type => "integer", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2012-07-13 09:22:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:4YMW4bgHrCBpUrFP6zaobQ

__PACKAGE__ -> belongs_to( canvas => 'SGA::SharedCanvas::Schema::Result::Canvas', 'canvas_id' );
__PACKAGE__ -> belongs_to( zone_annotation => 'SGA::SharedCanvas::Schema::Result::ZoneAnnotation', 'zone_annotation_id' );

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
