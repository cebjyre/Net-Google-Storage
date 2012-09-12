use strict;
use warnings;
package Net::Google::Storage;

# ABSTRACT: Access the Google Storage JSON API (currently experimental).
# https://developers.google.com/storage/docs/json_api/

use Moose;
use LWP::UserAgent;
use JSON;
use HTTP::Status qw(:constants);

use Net::Google::Storage::Bucket;

with 'Net::Google::Storage::Agent';

has projectId => (
	is => 'rw',
	isa => 'Int',
);

my $api_base = 'https://www.googleapis.com/storage/v1beta1/b';

sub list_buckets
{
	my $self = shift;
	
	my $projectId = $self->projectId;
	
	my $res = $self->get("$api_base?projectId=$projectId");
	
	die 'Failed to list buckets' unless $res->is_success;
	
	my $response = decode_json($res->decoded_content);
	
	my @buckets = map {Net::Google::Storage::Bucket->new($_)} @{$response->{items}};
	return \@buckets;
}

sub get_bucket
{
	my $self = shift;
	
	my $bucket_name = shift;
	
	my $res = $self->get("$api_base/$bucket_name");
	return undef if $res->code == HTTP_NOT_FOUND;
	die "Failed to get bucket: $bucket_name" unless $res->is_success;
	
	my $response = decode_json($res->decoded_content);
	
	return Net::Google::Storage::Bucket->new($response);
}

sub insert_bucket
{
	my $self = shift;
	
	my $bucket_args = shift;
	$bucket_args->{projectId} ||= $self->projectId;
	my $res = $self->post($api_base, $bucket_args);
	die "Failed to create bucket: $bucket_args->{id}" unless $res->is_success;
	
	my $response = decode_json($res->decoded_content);
	
	return Net::Google::Storage::Bucket->new($response);
}

sub delete_bucket
{
	my $self = shift;
	
	my $bucket_name = shift;
	
	my $res = $self->delete("$api_base/$bucket_name");
	die "Failed to delete bucket: $bucket_name" unless $res->is_success;
	
	return;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
