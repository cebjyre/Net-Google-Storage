package Net::Google::Storage::Test;
use base qw(Test::Class);

use Net::Google::Storage;

use autodie;
use Test::More;
use JSON;

sub _read_config : Test(startup)
{
	my $self = shift;
	
	$self->SKIP_ALL('No config file available') unless -e '../../config.json';
	open(my $fh, '<', '../../config.json');
	
	my $contents = join '', <$fh>;
	close $fh;
	
 	$self->{config} = decode_json($contents);
}

sub new_gs : Test(startup => 1)
{
	my $self = shift;
	my $config = $self->{config};
	$self->{gs} = Net::Google::Storage->new(
		client_id =>	 $config->{client_id},
		client_secret => $config->{client_secret},
		refresh_token => $config->{refresh_token},
		projectId =>	 $config->{projectId},
	);
	isa_ok($self->{gs}, 'Net::Google::Storage') or $self->BAILOUT('Unable to create Net::Google::Storage object');
}

sub _access_token_refresh : Test(5)
{
	my $self = shift;
	my $gs = $self->{gs};
	
	ok(!$gs->access_token, 'Access token does not exist');
	ok(!$gs->has_refreshed_access_token, 'Access token is not yet marked as refreshed');
	
	$gs->refresh_access_token;
	
	ok($gs->access_token, 'Access token exists');
	ok($gs->has_refreshed_access_token, 'Access token is marked as refreshed');
	
	my $expiry = $gs->access_token_expiry;
	cmp_ok($expiry, '>', time, 'Access token is set to expire in the future');
}

sub bucket_1_view : Test(6)
{
	my $self = shift;
	my $gs = $self->{gs};
	
	my $buckets = $gs->list_buckets;
	
	ok($buckets && @$buckets, 'We got at least one bucket');
	
	my $desired_bucket_name = $self->{config}->{test_bucket}->{name};
	my $desired_bucket_created = $self->{config}->{test_bucket}->{created};
	
	my @desired_buckets = grep {$_->id eq $desired_bucket_name} @$buckets;
	cmp_ok(scalar @desired_buckets, '==', 1, "We matched exactly one bucket for $desired_bucket_name");
	
	my $desired_bucket = $desired_buckets[0];
	isa_ok($desired_bucket, 'Net::Google::Storage::Bucket');
	is($desired_bucket->id, $desired_bucket_name);
	is($desired_bucket->timeCreated, $desired_bucket_created);
	
	my $explicitly_requested_bucket = $gs->get_bucket($desired_bucket_name);
	is_deeply($explicitly_requested_bucket, $desired_bucket)
}

sub bucket_2_create_delete : Test(7)
{
	my $self = shift;
	my $gs = $self->{gs};
	my $config = $self->{config};
	
	my $new_bucket_name = $config->{new_test_bucket}->{name};
	return 'No configs for creating buckets' unless $new_bucket_name;
	
	my $existing_bucket = $gs->get_bucket($new_bucket_name);
	is($existing_bucket, undef, 'Bucket does not exist yet') or return "Test bucket $new_bucket_name already exists";
	
	my $bucket = $gs->insert_bucket({id => $new_bucket_name});
	isa_ok($bucket, 'Net::Google::Storage::Bucket');
	is($bucket->id, $new_bucket_name);
	
	$bucket = undef;
	is($bucket, undef, 'Unset the bucket variable prior to refetching');
	$bucket = $gs->get_bucket($new_bucket_name);
	isa_ok($bucket, 'Net::Google::Storage::Bucket');
	is($bucket->id, $new_bucket_name);
	
	$gs->delete_bucket($new_bucket_name);
	
	$bucket = $gs->get_bucket($new_bucket_name);
	is($bucket, undef, 'Successfully gotten rid of the bucket')
}

1;
