use utf8;
package SGA::SharedCanvas::Schema::Result::TextAnnotationTextAnnotationList;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

SGA::SharedCanvas::Schema::Result::TextAnnotationTextAnnotationList

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

=head1 TABLE: C<text_annotation_text_annotation_list>

=cut

__PACKAGE__->table("text_annotation_text_annotation_list");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 text_annotation_id

  data_type: 'integer'
  is_nullable: 0

=head2 text_annotation_list_id

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "text_annotation_id",
  { data_type => "integer", is_nullable => 0 },
  "text_annotation_list_id",
  { data_type => "integer", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2012-08-10 09:55:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:jKcEDzIf3Yp5t8kR3Xhreg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
