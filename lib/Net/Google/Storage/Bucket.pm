use strict;
use warnings;
package Net::Google::Storage::Bucket;

# ABSTRACT: Interface for a Google Storage Bucket
# https://developers.google.com/storage/docs/json_api/v1/buckets#resource

use Moose;

use Net::Google::Storage::Types;

=head1 DESCRIPTION

Object for storing the data of a bucket, slightly cut down from
L<https://developers.google.com/storage/docs/json_api/v1/buckets#resource>.

Generally Net::Google::Storage::Bucket objects are acquired from a
C<get_bucket>, C<list_buckets>, or C<insert_bucket> call on a
L<Net::Google::Storage> object.

=attr id

The name of the bucket.

=cut

has id => (
	is => 'ro',
	isa => 'Str',
);

=attr projectId

The id of the project to which this bucket belongs.

=cut

has projectId => (
	is => 'ro',
	isa => 'Int',
);

=attr selfLink

The url of this bucket.

=cut

has selfLink => (
	is => 'ro',
	isa => 'Str'
);

=attr timeCreated

The creation date of the bucket in
L<RFC3339https://tools.ietf.org/html/rfc3339> format, eg
C<2012-09-16T07:00:26.982Z>.

=cut

has timeCreated => (
	is => 'ro',
	isa => 'Str',
);

=attr owner

Hashref of the owner details for the bucket - see
L<the docs|https://developers.google.com/storage/docs/json_api/v1/buckets#resource>.

=cut

has owner => (
	is => 'ro',
	isa => 'HashRef[Str]',
);

=attr location

Physical location of the servers containing this bucket, currently only C<US>
or C<EU>.

=cut

has location => (
	is => 'rw',
	isa => 'Net::Google::Storage::Types::BucketLocation',
	default => 'US',
);

no Moose;
__PACKAGE__->meta->make_immutable;

1;

