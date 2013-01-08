use utf8;
package SGA::SharedCanvas::Schema::Result::Image;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

SGA::SharedCanvas::Schema::Result::Image

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

=head1 TABLE: C<image>

=cut

__PACKAGE__->table("image");

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
  is_nullable: 1
  size: 255

=head2 size

  data_type: 'integer'
  is_nullable: 1

=head2 width

  data_type: 'integer'
  is_nullable: 1

=head2 height

  data_type: 'integer'
  is_nullable: 1

=head2 format

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=head2 url

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "uuid",
  { data_type => "char", is_nullable => 0, size => 20 },
  "label",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "size",
  { data_type => "integer", is_nullable => 1 },
  "width",
  { data_type => "integer", is_nullable => 1 },
  "height",
  { data_type => "integer", is_nullable => 1 },
  "format",
  { data_type => "varchar", is_nullable => 1, size => 64 },
  "url",
  { data_type => "varchar", is_nullable => 1, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2012-08-10 15:27:14
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:+9KlwqDn4D6qZNqmltiy/g

with 'SGA::SharedCanvas::Role::Schema::Result::UUID';

__PACKAGE__ -> has_many(image_annotations => 'SGA::SharedCanvas::Schema::Result::ImageAnnotation', 'image_id');

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
