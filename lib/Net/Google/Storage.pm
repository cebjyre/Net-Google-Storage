use strict;
use warnings;
package Net::Google::Storage;

# ABSTRACT: Access the Google Storage JSON API (currently experimental).
# https://developers.google.com/storage/docs/json_api/

use Moose;
use LWP::UserAgent;
use JSON;

has access_token => (
	is => 'rw',
	isa => 'Str',
);

has refresh_token => (
	is => 'ro',
	isa => 'Str',
);

has client_id => (
	is => 'ro',
	isa => 'Str',
	required => 1,
);

has client_secret => (
	is => 'ro',
	isa => 'Str',
	required => 1,
);

has project_id => (
	is => 'rw',
	isa => 'Int',
);

has has_refreshed_access_token => (
	is => 'rw',
	isa => 'Bool',
	default => 0,
);

has access_token_expiry => (
	is => 'rw',
	isa => 'Int',
);

has ua => (
	is => 'ro',
	isa => 'LWP::UserAgent',
	lazy => 1,
	builder => '_build_ua',
);

my $api_base = 'https://www.googleapis.com/storage/v1beta1/b';

sub refresh_access_token
{
	my $self = shift;
	
	my $ua = $self->ua;
	my $res = $ua->post('https://accounts.google.com/o/oauth2/token', {
		client_id => 	 $self->client_id,
		client_secret => $self->client_secret,
		refresh_token => $self->refresh_token,
		grant_type => 'refresh_token',
	});
	
	die 'Failed to refresh the access token' unless $res->is_success;
	
	my $response = decode_json($res->decoded_content);
	$self->access_token($response->{access_token});
	$self->access_token_expiry(time + $response->{expires_in});
	$self->has_refreshed_access_token(1);
}

sub _build_ua
{
	return LWP::UserAgent->new();
}

sub list_buckets
{
	my $self = shift;
	
	my $ua = $self->ua;
	my $project_id = $self->project_id;
	
	my $res = $ua->get("$api_base?projectId=$project_id", Authorization => "OAuth " . $self->access_token);
	
	die 'Failed to list buckets' unless $res->is_success;
	
	my $response = decode_json($res->decoded_content);
	return $response->{items};
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
