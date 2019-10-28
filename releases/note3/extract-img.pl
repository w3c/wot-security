#!/usr/bin/perl

while (<>) {
  chomp;
  if (/"(images\/.*?)"/) {
    print "$1\n";
  }
}

