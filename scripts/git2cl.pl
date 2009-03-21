#! /usr/bin/perl -w

use warnings;
use strict;
use XML::Simple;
use Data::Dumper;
use Date::Parse;
use Text::Wrap qw(wrap fill);

open(LOG, "git log origin/master --date=short --pretty=format:'%h%x00%an%x00%ae%x00%ad%x00%s'|");
my %dates;
my %authors;
my $lsub = '';
while(<LOG>) {
  chomp();
  my ($hash,$author,$email,$date,$subject) = split(/\0/,$_);
  if (! exists($authors{$email})) {
    $authors{$email}=$author;
  }
  next if ($subject =~ /^Merge branch 'master/);
  next if ($subject =~ /^Indent and submodule update/);
  next if ($subject =~ /^Indent run/);
  next if ($subject eq $lsub);
  $lsub = $subject;
  my $entry = wrap("    $hash  ", "             ", $subject);
  if (! exists($dates{$date})) {
    $dates{$date} = {};
  }
  if (! exists($dates{$date}{$email})) {
    $dates{$date}{$email} = ();
  }
  push @{$dates{$date}{$email}},$entry;
}
close(LOG);
open(C, ">CHANGES");
foreach my $date (reverse sort keys %dates) {
  print C $date."\n";
  my $h = $dates{$date};
  my $first = 1;
  foreach my $author (sort keys %$h) {
    print C "  ".$authors{$author}." <$author>\n";
    print C join("\n", @{$dates{$date}{$author}});
    print C "\n\n";
  }
}
close(C);
