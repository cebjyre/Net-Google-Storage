use strict;
use warnings;
package Net::Google::Storage::Object;

# ABSTRACT: Interface for a Google Storage Object
# https://developers.google.com/storage/docs/json_api/v1/objects#resource

use Moose;

use Net::Google::Storage::Types;

has id => (
	is => 'ro',
	isa => 'Str',
);

has selfLink => (
	is => 'ro',
	isa => 'Str'
);

has name => (
	is => 'ro',
	isa => 'Str',
);

has bucket => (
	is => 'ro',
	isa => 'Str',
);

has media => (
	is => 'ro',
	isa => 'HashRef',
);

has contentEncoding => (
	is => 'ro',
	isa => 'Str',
);

has contentDisposition => (
	is => 'ro',
	isa => 'Str',
);

has cacheControl => (
	is => 'ro',
	isa => 'Str',
);

has metadata => (
	is => 'ro',
	isa => 'HashRef[Str]',
);

has owner => (
	is => 'ro',
	isa => 'HashRef[Str]',
);

no Moose;
__PACKAGE__->meta->make_immutable;

1;

