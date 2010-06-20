#!/usr/bin/perl

# Copyright 2010 by Jim Belton
# Licensed under the Artistic License (see http://www.perl.com/pub/a/language/misc/Artistic.html)
# Requires perl (on Windows, I recommend ActivePerl)
# and Audio::Wav from CPAN (http://cpan.uwinnipeg.ca/htdocs/Audio-Wav/Audio/Wav.html)
# Audio::Wav can be downloaded for ActivePerl using the Perl Package Manager program

use strict;
use warnings;
use FindBin qw($Bin);
use lib $Bin;   # Allows you to install Audio/Wav.pm in the same directory as csvtowav.pl
use Audio::Wav;

my $channels;       # derived from the number of columns if not specified
my $repetitions     = 1;
my $bits_per_sample = 16;
my $sample_rate     = 22100;
my $scale           = 1;
my $samples;        # unused for now
my $normalized;

my $origin          = 1;   # First column that contains channel data values
my $minimum;
my $maximum;
my %opt;

if ($ARGV[0] || "" eq "-a") {
	shift(@ARGV);
	$opt{a} = 1;
}

scalar(@ARGV) == 1 or die(<<EOF);
usage: csvtowav.pl [-a] <input.csv> - generate a wav file from a text file
    -a = Output an audition compatible version of the input file
EOF

my $file = $ARGV[0];
open(my $input, $file) or die("Can't open $file");
my $line;

while ($line = <$input>) {
	if ($line =~ /^([A-Za-z]+):\s+(\d*)/) {
		if    ($1 eq "SAMPLES")       { $samples         = $2 }
		elsif ($1 eq "BITSPERSAMPLE") { $bits_per_sample = $2 }
		elsif ($1 eq "CHANNELS")      { $channels        = $2 }
		elsif ($1 eq "SAMPLERATE")    { $sample_rate     = $2 }
		elsif ($1 eq "REPETITIONS")   { $repetitions     = $2 }
		elsif ($1 eq "SCALE")         { $scale           = $2 }
		elsif ($1 eq "NORMALIZED")    { $normalized      = $2 if ($2 ne "FALSE"); }
		else                          { die("Unsupported parameter: $1"); }

		next;
	}

	last;
}

print STDERR "line:".$line;

while ($line =~ /^\(?\w+\)?[,\s]\s*\(?\w+\)?/) {
	print STDERR "Discarding header line: $line";
	$line = <$input>;
}

while ($line =~ /^\s+$/) {
	print STDERR "Discarding blank header line: $line";
	$line = <$input>;
}

my $wav_factory = new Audio::Wav;
my @samples = ();
my $i;
my $wav;

while (defined($line)) {
	my @cells   = split(/[,\s]\s*/, $line);
	my $columns = scalar(@cells);

	if (!defined($channels)) {
		if ($columns == 1) {
			$origin   = 0;
			$channels = 1;
		}
		else {
			$channels = $columns - 1;
		}
	}
	else {
		$origin = $columns - $channels;
	}

	if (!defined($wav)) {
		my $details = {
			'bits_sample'	=> $bits_per_sample,
			'sample_rate'	=> $sample_rate,
			'channels'	    => $channels,
			# if you'd like this module not to use a write cache, uncomment the next line
			#'no_cache'	=> 1,
		};

	    $wav = $wav_factory->write('testout.wav', $details);
	}

	if ($columns != $channels + $origin) {
		die("Row does not have ".($channels + $origin)." cells");
	}

	for ($i = $origin; $i < $channels + $origin; $i++) {
		push(@samples, $cells[$i] * $scale);
	}

	$line = <$input>;
}

print STDERR "About to count samples\n";
my $number_of_samples = scalar(@samples);
print STDERR "Number of samples ".$number_of_samples."\n";

for (my $i = 1; $i <= $repetitions; $i++) {
	for (my $j = 0; $j < $number_of_samples; $j += $channels) {
		$wav->write(@samples[$j .. $j + $channels - 1]);
	}

	print STDERR ".";
}

print STDERR "\nAbout to write the wav file out\n";
$wav->finish();
