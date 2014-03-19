use utf8;
package KohaProfile::Schema::Result::Commit;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

KohaProfile::Schema::Result::Commit

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<commits>

=cut

__PACKAGE__->table("commits");

=head1 ACCESSORS

=head2 sha

  data_type: 'char'
  is_nullable: 0
  size: 40

=head2 title

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 added

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "sha",
  { data_type => "char", is_nullable => 0, size => 40 },
  "title",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "added",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</sha>

=back

=cut

__PACKAGE__->set_primary_key("sha");

=head1 RELATIONS

=head2 datapoints

Type: has_many

Related object: L<KohaProfile::Schema::Result::Datapoint>

=cut

__PACKAGE__->has_many(
  "datapoints",
  "KohaProfile::Schema::Result::Datapoint",
  { "foreign.sha" => "self.sha" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-03-19 10:08:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:VsLVG8bVvTaqf8ZrKsF3bA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
