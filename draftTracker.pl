#!/usr/bin/env perl

use strict;

use Net::Twitter;
use LWP::UserAgent; 
use XML::Simple;
use Data::Dumper;
use DBI;

my $numTeams = 12;

my $consumer_key =        "CONSUMER_KEY";
my $consumer_secret =     "CONSUME_SECRET";
my $access_token =        "ACCESS_TOKEN";
my $access_token_secret = "ACCESS_TOKEN_SECRET";

my $league = shift;
my $year = shift; 

my $database = 'adp';
my $hostname = '127.0.0.1';
my $user = 'root';
my $password = '';

my $dsn = "DBI:mysql:database=$database;host=$hostname";
my $dbh = DBI->connect($dsn, $user, $password);

my $sth = $dbh->prepare("select max(pick) as lastpick from draftTracker;");
$sth->execute();
my $ref = $sth->fetchrow_hashref();

my $lastPick = 0;
$lastPick = $ref->{lastpick} if $ref->{lastpick};

print "The last pick was: $lastPick\n";

#by default LWP won't follow a redirect after a post
my $redir=[qw(GET HEAD POST)];
my $ua=LWP::UserAgent->new(cookie_jar => {}, requests_redirectable=>$redir);

#request the page, following redirects
my $response=$ua->request(HTTP::Request->new(GET=>'http://football4.myfantasyleague.com/'.$year.'/export?TYPE=draftResults&L='.$league.'&W='));

#print $response->content;

my $simple = XML::Simple->new();
my $data = $simple->XMLin($response->content, ForceArray => ['draftPick'], keyattr => []);

#print Dumper($data) . "\n";

my @picks = @{$data->{draftUnit}->{draftPick}};

foreach my $pick (@picks) {
  
  my $truePick = (($pick->{round} - 1) * $numTeams) + $pick->{pick};
  
  last if not ($pick->{player} && $pick->{timestamp});
  next if $truePick <= $lastPick;
  
  my $playerHandle = $dbh->prepare("select * from players where id = '$pick->{player}'");
  $playerHandle->execute();
  my $playerRef = $playerHandle->fetchrow_hashref();
  
  my $franchiseHandle = $dbh->prepare("select * from franchises where id = '$pick->{franchise}';");
  $franchiseHandle->execute();
  my $franchiseRef = $franchiseHandle->fetchrow_hashref();
  
  my ($last, $first) = split(/, /, $playerRef->{name}); 
  my $name = $first . " " . $last;
  
  my $modifier = "st";
  $modifier = "nd" if $truePick == 2;
  $modifier = "rd" if $truePick == 3;
  $modifier = "th" if $truePick > 3;
  
  my $message =  "$name was selected by $franchiseRef->{name} with the $truePick".$modifier." overall pick ($pick->{round}.$pick->{pick}), he is a $playerRef->{position} with the $playerRef->{team}.\n";
  $message .= "$name is a rookie\n" if $playerRef->{status} eq "R";
  
  my $nt = Net::Twitter->new(
      traits   => [qw/OAuth API::REST/],
      consumer_key        => $consumer_key,
      consumer_secret     => $consumer_secret,
      access_token        => $access_token,
      access_token_secret => $access_token_secret,
  );
  
  $nt->update($message);
  
  print $message;
  
  $dbh->do("INSERT INTO draftTracker (leagueID, playerID, pick, franchise, draftTime) VALUES" .
        "($league, '$pick->{player}', $truePick, '$pick->{franchise}', '$pick->{timestamp}')");
  
  $playerHandle->finish;
  
  sleep(30);
}

$sth->finish;
$dbh->disconnect;