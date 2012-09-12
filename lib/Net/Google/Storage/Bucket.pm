use strict;
use warnings;
package Net::Google::Storage::Bucket;

# ABSTRACT: Interface for a Google Storage Bucket
# https://developers.google.com/storage/docs/json_api/v1/buckets#resource

use Moose;

use Net::Google::Storage::Types;

has id => (
	is => 'ro',
	isa => 'Str',
);

has projectId => (
	is => 'ro',
	isa => 'Int',
);

has selfLink => (
	is => 'ro',
	isa => 'Str'
);

has timeCreated => (
	is => 'ro',
	isa => 'Str',
);

has owner => (
	is => 'ro',
	isa => 'HashRef[Str]',
);

has location => (
	is => 'rw',
	isa => 'Net::Google::Storage::Types::BucketLocation',
	default => 'US',
);

no Moose;
__PACKAGE__->meta->make_immutable;

1;

