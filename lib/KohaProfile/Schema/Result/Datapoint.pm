use utf8;
package KohaProfile::Schema::Result::Datapoint;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

KohaProfile::Schema::Result::Datapoint

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

=head1 TABLE: C<datapoints>

=cut

__PACKAGE__->table("datapoints");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 run_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 sha

  data_type: 'char'
  is_foreign_key: 1
  is_nullable: 0
  size: 40

=head2 sha_order

  data_type: 'integer'
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 128

=head2 method

  data_type: 'varchar'
  is_nullable: 0
  size: 128

=head2 value

  data_type: 'float'
  is_nullable: 0

=head2 created

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "run_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "sha",
  { data_type => "char", is_foreign_key => 1, is_nullable => 0, size => 40 },
  "sha_order",
  { data_type => "integer", is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 128 },
  "method",
  { data_type => "varchar", is_nullable => 0, size => 128 },
  "value",
  { data_type => "float", is_nullable => 0 },
  "created",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 run

Type: belongs_to

Related object: L<KohaProfile::Schema::Result::Run>

=cut

__PACKAGE__->belongs_to(
  "run",
  "KohaProfile::Schema::Result::Run",
  { id => "run_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "RESTRICT" },
);

=head2 sha

Type: belongs_to

Related object: L<KohaProfile::Schema::Result::Commit>

=cut

__PACKAGE__->belongs_to(
  "sha",
  "KohaProfile::Schema::Result::Commit",
  { sha => "sha" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "RESTRICT" },
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-03-20 10:45:05
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:2KyLrQVua3wGCDi2cda89g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
