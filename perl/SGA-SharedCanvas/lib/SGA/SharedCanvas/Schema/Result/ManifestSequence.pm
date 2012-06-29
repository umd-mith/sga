use utf8;
package SGA::SharedCanvas::Schema::Result::ManifestSequence;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

SGA::SharedCanvas::Schema::Result::ManifestSequence

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

=head1 TABLE: C<manifest_sequence>

=cut

__PACKAGE__->table("manifest_sequence");

=head1 ACCESSORS

=head2 manifest_id

  data_type: 'integer'
  is_nullable: 0

=head2 sequence_id

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "manifest_id",
  { data_type => "integer", is_nullable => 0 },
  "sequence_id",
  { data_type => "integer", is_nullable => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2012-06-27 13:29:41
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:QWupfWiv6bvgndlWhcXpvw

__PACKAGE__ -> belongs_to( 'manifest' => 'SGA::SharedCanvas::Schema::Result::Manifest', 'manifest_id' );
__PACKAGE__ -> belongs_to( 'sequence' => 'SGA::SharedCanvas::Schema::Result::Sequence', 'sequence_id' );

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
