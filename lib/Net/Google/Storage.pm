use strict;
use warnings;
use autodie;
package Net::Google::Storage;

# ABSTRACT: Access the Google Storage JSON API (currently experimental).
# https://developers.google.com/storage/docs/json_api/

use Moose;
use LWP::UserAgent;
use JSON;
use HTTP::Status qw(:constants);

use Net::Google::Storage::Bucket;
use Net::Google::Storage::Object;

with 'Net::Google::Storage::Agent';

has projectId => (
	is => 'rw',
	isa => 'Int',
);

my $api_base = 'https://www.googleapis.com/storage/v1beta1/b';
my $upload_api_base = 'https://www.googleapis.com/upload/storage/v1beta1/b';

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
	
	my $res = $self->get($self->_form_url("$api_base/%s", $bucket_name));
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
	my $res = $self->json_post($api_base, $bucket_args);
	die "Failed to create bucket: $bucket_args->{id}" unless $res->is_success;
	
	my $response = decode_json($res->decoded_content);
	
	return Net::Google::Storage::Bucket->new($response);
}

sub delete_bucket
{
	my $self = shift;
	
	my $bucket_name = shift;
	
	my $res = $self->delete($self->_form_url("$api_base/%s", $bucket_name));
	die "Failed to delete bucket: $bucket_name" unless $res->is_success;
	
	return;
}

sub get_object
{
	my $self = shift;
	
	my %args = @_;
	
	my $res = $self->get($self->_form_url("$api_base/%s/o/%s?alt=json", $args{bucket}, $args{object}));
	return undef if $res->code == HTTP_NOT_FOUND;
	die "Failed to get object: $args{object} in bucket: $args{bucket}" unless $res->is_success;
	
	my $response = decode_json($res->decoded_content);
	
	return Net::Google::Storage::Object->new($response);
}

sub download_object
{
	my $self = shift;
	
	my %args = @_;
	
	my $res = $self->get($self->_form_url("$api_base/%s/o/%s", $args{bucket}, $args{object}), ':content_file' => $args{filename});
	return undef if $res->code == HTTP_NOT_FOUND;
	die "Failed to get object: $args{object} in bucket: $args{bucket}" unless $res->is_success;
}

sub list_objects
{
	my $self = shift;
	
	my $bucket = shift;
	
	my $res = $self->get($self->_form_url("$api_base/%s/o", $bucket));
	
	die 'Failed to list objects' unless $res->is_success;
	
	my $response = decode_json($res->decoded_content);
	
	my @objects = map {Net::Google::Storage::Object->new($_)} @{$response->{items}};
	return \@objects;
}

sub insert_object
{
	my $self = shift;
	
	my %args = @_;
	
	my $url = $self->_form_url("$upload_api_base/%s/o?uploadType=resumable", $args{bucket});
	my $filename = $args{filename} || die 'A filename is required';
	
	die "Unable to find $filename" unless -e $filename;
	my $filesize = -s _;
	
	my $object_hash = $args{object};
	unless($object_hash->{media}->{contentType})
	{
		require LWP::MediaTypes;
		$object_hash->{media}->{contentType} = LWP::MediaTypes::guess_media_type($filename);
	}
	
	my $content_type = $object_hash->{media}->{contentType};
	my $res = $self->json_post($url, 'X-Upload-Content-Type' => $content_type, 'X-Upload-Content-Length' => $filesize, $object_hash);
	my $resumable_url = $res->header('Location');
	
	my %headers = (
		'Content-Length' => $filesize,
		'Content-Type' => $content_type,
	);
	
	local $/;
	open(my $fh, '<', $filename);
	my $file_contents = <$fh>;
	
	$res = $self->put($resumable_url, %headers, Content => $file_contents);
	
	#resuming code
	my $retry_count = 0;
	my $code = $res->code;
	while($code >=500 && $code <600 && $retry_count++ < 8)
	{
		sleep 2**$retry_count;
		$res = $self->put($resumable_url, 'Content-Length' => 0, 'Content-Range' => "bytes */$filesize");
		last if $res->is_success;
		next unless $res->code == 308;
		
		my $range = $res->header('Range');
		next unless $range;
		
		if($range =~ /bytes=0-(\d+)/)
		{
			my $offset = $1+1;
			seek($fh, $offset, 0);
			$file_contents = <$fh>;
			
			%headers = (
				'Content-Length' => $filesize - $offset,
				'Content-Range' => sprintf('bytes %d-%d/%d', $offset, $filesize-1, $filesize),
			);
			$res = $self->put($resumable_url, %headers, Content => $file_contents);
			$code = $res->code;
		}
		else
		{
			next;
		}
	}
	
	my $response = decode_json($res->decoded_content);
	
	return Net::Google::Storage::Object->new($response);
}

sub delete_object
{
	my $self = shift;
	
	my %args = @_;
	
	my $res = $self->delete($self->_form_url("$api_base/%s/o/%s", $args{bucket}, $args{object}));
	die "Failed to delete object: $args{object} in bucket: $args{bucket}" unless $res->is_success;
	
	return;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
