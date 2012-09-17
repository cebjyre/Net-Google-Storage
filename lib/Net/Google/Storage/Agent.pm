use strict;
use warnings;
package Net::Google::Storage::Agent;

# ABSTRACT: Access the Google Storage JSON API (currently experimental).
# https://developers.google.com/storage/docs/json_api/

use Moose::Role;
use LWP::UserAgent 6.04;
use JSON;
use URI::Escape 3.29;

=head1 DESCRIPTION

Role-module for L<Net::Google::Storage>, handles the http communication side
of things.

Some or all of the following attributes should be passed in as an argument to
L<Net::Google::Storage/new>

=attr access_token

An OAuth2 access token used to actually access the resources.

=cut

has access_token => (
	is => 'rw',
	isa => 'Str',
);

=attr refresh_token

An OAuth2 refresh token used for acquiring a new L</access_tokens> - you
don't need both a refresh_token and an access_token, but you'll need at least
one of them.

=cut

has refresh_token => (
	is => 'ro',
	isa => 'Str',
);

=attr client_id

The client ID for the user being authenticated - retrieved from Google's
L<API Console|https://code.google.com/apis/console/#access>.

Required for refreshing access tokens (ie provide if you are also providing
the L</refresh_token>).

=cut

has client_id => (
	is => 'ro',
	isa => 'Str',
);

=attr client_secret

Counterpart to the client ID, also retrieved from the API Console.

Again, only required for refreshing access tokens.

=cut

has client_secret => (
	is => 'ro',
	isa => 'Str',
);

=method has_refreshed_access_token

Call without parameters to find whether the L</access_token> has been
refreshed.

Call with a false value to indicate you know about that refresh, so future
calls without any parameters will still be useful.

=cut

has has_refreshed_access_token => (
	is => 'rw',
	isa => 'Bool',
	default => 0,
);

=attr access_token_expiry

The time (in seconds since the epoch) at which the access_token will be
invalidated. Not required, but if supplied with the L</access_token> it
B<will> be trusted, and token refresh will be attempted after this time
without attempting communication.

=cut

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

=method refresh_access_token

Call (on the L<Net::Google::Storage> object) to refresh the access token.
Requires the C<client_id>, the C<client_secret> and the C<refresh_token> to
all be set. Updates the C<access_token>, the C<access_token_expiry> and
C<has_refreshed_access_token> will start returning true.

=cut

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

sub _get
{
	my $self = shift;
	my $ua = $self->_ua;
	
	my $res = $ua->get(@_);
	
	return $res;
}

sub _post
{
	my $self = shift;
	my $ua = $self->_ua;
	
	my $res = $ua->post(@_);
	return $res;
}

sub _json_post
{
	my $self = shift;
	
	my $args = pop;
	return $self->_post(@_, 'Content-Type' => 'application/json', Content => encode_json($args));
}

sub _delete
{
	my $self = shift;
	my $ua = $self->_ua;
	
	my $res = $ua->delete(@_);
	return $res;
}

sub _put
{
	my $self = shift;
	my $ua = $self->_ua;
	
	my $res = $ua->put(@_);
	return $res;
}

around [qw(_get _post _delete _put)] => sub {
	my $orig = shift;
	my $self = shift;
	
	my $ua = $self->_ua;
	my $expiry = $self->access_token_expiry;
	
	if((!$ua->default_header('Authorization')) || ($expiry && $expiry < time))
	{
		$self->_set_auth_header;
	}
	
	my $res = $self->$orig(@_);
	if($res->code == 401 && $self->refresh_token)
	{
		$self->refresh_access_token;
		$res = $self->$orig(@_);
	}
	
	return $res;
};

sub _form_url
{
	my $self = shift;
	
	my $format = shift;
	my @args = map {uri_escape_utf8($_)} @_;
	
	return sprintf $format, @args;
}

1;
