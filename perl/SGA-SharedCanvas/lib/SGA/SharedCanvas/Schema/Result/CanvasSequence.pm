use utf8;
package SGA::SharedCanvas::Schema::Result::CanvasSequence;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

SGA::SharedCanvas::Schema::Result::CanvasSequence

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

=head1 TABLE: C<canvas_sequence>

=cut

__PACKAGE__->table("canvas_sequence");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 canvas_id

  data_type: 'integer'
  is_nullable: 0

=head2 sequence_id

  data_type: 'integer'
  is_nullable: 0

=head2 position

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "canvas_id",
  { data_type => "integer", is_nullable => 0 },
  "sequence_id",
  { data_type => "integer", is_nullable => 0 },
  "position",
  { data_type => "integer", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2012-06-27 13:59:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:oGkOv1LjCuyl+XYONt0OLw

__PACKAGE__ -> load_components( "Ordered" );

__PACKAGE__ -> position_column("position");
__PACKAGE__ -> grouping_column("sequence_id");

__PACKAGE__ -> belongs_to( 'canvas' => 'SGA::SharedCanvas::Schema::Result::Canvas', 'canvas_id' );
__PACKAGE__ -> belongs_to( 'sequence' => 'SGA::SharedCanvas::Schema::Result::Sequence', 'sequence_id' );

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
