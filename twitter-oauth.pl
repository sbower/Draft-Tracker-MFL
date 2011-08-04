#!/usr/bin/env perl

use Net::Twitter;

my %consumer_tokens = (
    consumer_key    => '15mmO6mPAwQNpzVkyoGqEw',
    consumer_secret => '38qPi65HayUQbpcFL8y5Wqpy5J0rScThikcqRYJ7QrE',
);

my $nt = Net::Twitter->new( traits => [qw/API::REST OAuth/], %consumer_tokens );

my $auth_url = $nt->get_authorization_url;
print "$auth_url\n";
my $pin = <STDIN>;    
chomp $pin;

# Autorisierung mit PIN#
my ( $access_token, $access_token_secret, $user_id, $screen_name ) =
  $nt->request_access_token( verifier => $pin )
  or die $!;
  
print "$access_token\n";
print "$access_token_secret\n";