package Net::Google::Storage::Types;

# ABSTRACT: Types library for L<Net::Google::Storage>. Pretty boring really.

use Moose::Util::TypeConstraints;

enum 'Net::Google::Storage::Types::BucketLocation' => ['US', 'EU'];

1;