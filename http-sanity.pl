#!/usr/bin/perl

while(<>) {
  s/^Date: (.*)/Date: TODAY/;
  s/^Server: Apache(.*)/Server: Apache VERSION/;
  print;
}

