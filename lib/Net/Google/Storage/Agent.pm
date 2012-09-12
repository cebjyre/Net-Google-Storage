use strict;
use warnings;
package Net::Google::Storage::Agent;

# ABSTRACT: Access the Google Storage JSON API (currently experimental).
# https://developers.google.com/storage/docs/json_api/

use Moose::Role;
use LWP::UserAgent 6.04;
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

has has_refreshed_access_token => (
	is => 'rw',
	isa => 'Bool',
	default => 0,
);

has access_token_expiry => (
	is => 'rw',
	isa => 'Int',
);

has _ua => (
	is => 'ro',
	isa => 'LWP::UserAgent',
	lazy => 1,
	builder => '_build_ua',
);

sub _build_ua
{
	my $self = shift;
	my $ua = LWP::UserAgent->new(agent => 'Net::Google::Storage ');
	
	my @encodings = HTTP::Message::decodable;
	if(grep {$_ eq 'gzip'} @encodings)
	{
		$ua->agent($ua->agent . ' (gzip)');
		$ua->default_header('Accept-Encoding' => join ', ', @encodings);
	}
	
	return $ua;
}

sub _set_auth_header
{
	my $self = shift;
	my $ua = $self->_ua;
	
	if($self->access_token)
	{
		$ua->default_header(Authorization => "OAuth " . $self->access_token);
	}
	elsif($self->refresh_token)
	{
		$self->refresh_access_token
	}
}

sub refresh_access_token
{
	my $self = shift;
	
	my $ua = $self->_ua;
	my $res = $ua->post('https://accounts.google.com/o/oauth2/token', {
		client_id => $self->client_id,
		client_secret => $self->client_secret,
		refresh_token => $self->refresh_token,
		grant_type => 'refresh_token',
	});
	
	die 'Failed to refresh the access token' unless $res->is_success;
	
	my $response = decode_json($res->decoded_content);
	$self->access_token($response->{access_token});
	$self->access_token_expiry(time + $response->{expires_in});
	$self->has_refreshed_access_token(1);
	$self->_set_auth_header;
}

sub get
{
	my $self = shift;
	my $ua = $self->_ua;
	
	my $url = shift;
	my $res = $ua->get($url);
	
	return $res;
}

sub post
{
	my $self = shift;
	my $ua = $self->_ua;
	
	my $url = shift;
	my $bucket_args = shift;
	my $res = $ua->post($url, 'Content-Type' => 'application/json', Content => encode_json($bucket_args));
	return $res;
}

sub delete
{
	my $self = shift;
	my $ua = $self->_ua;
	
	my $url = shift;
	my $res = $ua->delete($url);
	return $res;
}

before [qw(get post delete)] => sub {
	my $self = shift;
	
	my $ua = $self->_ua;
	my $expiry = $self->access_token_expiry;
	
	if((!$ua->default_header('Authorization')) || ($expiry && $expiry < time))
	{
		$self->_set_auth_header;
	}
};

1;
