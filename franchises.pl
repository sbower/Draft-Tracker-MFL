#!/usr/bin/env perl

use strict;

use LWP::UserAgent; 
use HTTP::Cookies;
use XML::Simple;
use Data::Dumper;
use DBI;

my $database = 'adp';
my $hostname = '127.0.0.1';
my $user = 'root';
my $password = '';

my $league = shift;
my $year = shift;

my $dsn = "DBI:mysql:database=$database;host=$hostname";
my $dbh = DBI->connect($dsn, $user, $password);

#by default LWP won't follow a redirect after a post
my $redir=[qw(GET HEAD POST)];
my $ua=LWP::UserAgent->new(cookie_jar => {}, requests_redirectable=>$redir);

#request the page, following redirects
my $response=$ua->request(HTTP::Request->new(GET=>'http://football.myfantasyleague.com/'.$year.'/export?TYPE=league&L='.$league.'&W='));

my $simple = XML::Simple->new();
my $data = $simple->XMLin($response->content, ForceArray => ['franchise'], keyattr => []);
my @franchises = @{$data->{franchises}->{franchise}};

foreach my $franchise (@franchises) {
  $dbh->do("INSERT INTO franchises (id, name, division) VALUES" .
        "('$franchise->{id}', \"$franchise->{name}\", '$franchise->{division}')");
}