use strict;
use warnings;
package Net::Google::Storage::Object;

# ABSTRACT: Interface for a Google Storage Object
# https://developers.google.com/storage/docs/json_api/v1/objects#resource

use Moose;

use Net::Google::Storage::Types;

=head1 DESCRIPTION

Object for storing the data of an object, slightly cut down from
L<https://developers.google.com/storage/docs/json_api/v1/objects#resource>.

Generally Net::Google::Storage::Object objects are acquired from a
C<get_object>, C<list_objects>, or C<insert_object> call on a
L<Net::Google::Storage> object.

=attr id

The id of the object. Essentially the concatenation of the
L<bucket name|/bucket> and the L<object's name|/name>.

=cut

has id => (
	is => 'ro',
	isa => 'Str',
);

=attr selfLink

The url of this object.

=cut

has selfLink => (
	is => 'ro',
	isa => 'Str'
);

=attr name

The name of the object within the bucket. B<This is what you want to adjust,
not the id.>

=cut

has name => (
	is => 'ro',
	isa => 'Str',
);

=attr bucket

The name of the bucket the object resides within.

=cut

has bucket => (
	is => 'ro',
	isa => 'Str',
);

=attr media

A hashref containing sundry information about the file itself - check out the
L<docs|https://developers.google.com/storage/docs/json_api/v1/objects#resource>.

=cut

has media => (
	is => 'ro',
	isa => 'HashRef',
);

=attr contentEncoding

The content encoding of the object's data.

=cut

has contentEncoding => (
	is => 'ro',
	isa => 'Str',
);

=attr contentDisposition

The content disposition of the object's data.

=cut

has contentDisposition => (
	is => 'ro',
	isa => 'Str',
);

=attr cacheControl

Cache-Control directive for the object data.

=cut

has cacheControl => (
	is => 'ro',
	isa => 'Str',
);

=attr metadata

Hashref containing user-defined metadata for the object.

=cut

has metadata => (
	is => 'ro',
	isa => 'HashRef[Str]',
);

=attr owner

Hashref containing details for the object's owner.

=cut

has owner => (
	is => 'ro',
	isa => 'HashRef[Str]',
);

no Moose;
__PACKAGE__->meta->make_immutable;

1;

