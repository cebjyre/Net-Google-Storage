package Net::Google::Storage::Types;

use Moose::Util::TypeConstraints;

enum 'Net::Google::Storage::Types::BucketLocation' => ['US', 'EU'];

1;