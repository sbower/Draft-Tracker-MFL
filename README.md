Overview
=============
This will allow you to tweet the results of a slow MFL draft while its in progress

Installation
=============

Create key
-------------

1. ./twitter-oauth.pl
2. Visit the website URL that it spits out
3. Enter the pin number
4. Record the ACCESS_TOKEN and ACCESS_TOKEN_SECRET

Create database
-------------
mysql> create table players (id varchar(5) primary key, name varchar(150), position varchar(50), team varchar(250), status varchar(50));
mysql> create table draftTracker (id int auto_increment primary key, leagueID varchar(10), playerID varchar(5), pick int, franchise varchar(250), draftTime int);
mysql> create table franchises (id varchar(4), name varchar(255), division varchar(2));

run players.pl with the current year
run franchises.pl with current year and league number

Cron the DrafTracker
------------

Edit your cromtab to run draftTracker.pl every five minutes.