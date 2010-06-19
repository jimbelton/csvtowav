#!/usr/bin/perl

use strict;
use warnings;
use File::Compare;

use FindBin qw($Bin);
use Test::More tests => 3;

chdir( "$Bin") or die("Can't chdir to $Bin");
unlink("440HzPicoscope100ms.aud");
ok(system("../csvtowav.pl -a 440HzPicoscope100ms.txt") == 0,              "csvtowav.pl -a succeeded");
ok(-f "440HzPicoscope100ms.aud",                                          "audition file was produced");
ok(compare("440HzPicoscope100ms.aud","440HzPicoscope100ms.aud.exp") == 0, "audition file was as expected");
