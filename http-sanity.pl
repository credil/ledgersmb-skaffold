#!/usr/bin/perl

while(<>) {
  s/^Date: (.*)/Date: TODAY/;
  print;
}

