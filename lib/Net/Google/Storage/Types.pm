package Net::Google::Storage::Types;

# ABSTRACT: Types library for L<Net::Google::Storage>. Pretty boring really.

use Moose::Util::TypeConstraints;

subtype 'Net::Google::Storage::Types::BucketLocation', as 'Str';

1;
