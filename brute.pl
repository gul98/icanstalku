#!/usr/bin/perl
#
# brute.pl
#
# A perl script to analyze a brute force and analyze photos posted to 
# certain photo services for location related EXIF tags ("geo-tags") 
# and output the location.
#
# Copyright (c) 2010, Ben Jackson and Mayhemic Labs - bbj@mayhemiclabs.com
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of the author nor the names of contributors may be
#       used to endorse or promote products derived from this software without
#       specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

use strict;
use Reaper;
use Getopt::Long;

$| = 1;
my $full = 0;
my $debug = 0;
my ($service, $start, $save);
my $directory="./";

my $args = GetOptions (	"service=s" => \$service,
			"full" => \$full,
			"debug" => \$debug,
			"start=s" => \$start,
			"directory=s" => \$directory,
			"save" => \$save); 

my $error_condition = 0;

if (!$service){
	print localtime() . " Errr... Pretty cowardly not giving me a service...\n";
	$error_condition = 1;
}

if (!$start){
	print localtime() . " Errr... With what URL do I start?\n";
	$error_condition = 1;
}

if ($error_condition) {
	die();
}

my ($photo_base_url,$photo_tail_url,$url_combo);

if ($service eq "twitpic"){
	$photo_base_url = "http://www.twitpic.com/";
	$url_combo = "0123456789abcdefghijklmnopqrstuvwxyz";
}else{
	print localtime() . " I don't know how to process the '$service' service.\n";
	die();	
}

my $brute = $start;

while (1){

	my $url = $photo_base_url . $brute;

	print "Downloading $url...\n";
	my $picture = Reaper::DownloadImage($url);

	my $tags;

	if ($picture){
		$tags = Reaper::GetTags(\$picture);
		if ($save){
			if ((!-d $directory)){
				mkdir($directory);
			}
	
			open(F,">$directory/$brute.jpg");
			print F $picture;
			close F;
		}

	}else{
		warn "Could Not Download Image :(";
	}

	if ($tags){

		if($save){
			open(F,">$directory/$brute" . "_exif.txt");
			foreach (keys %$tags) {
				my $val = $$tags{$_};

				if (ref $val eq 'ARRAY') {
					$val = join(', ', @$val);
				} elsif (ref $val eq 'SCALAR') {
					$val = '(Binary data)';
				}
	
				printf F ("%-24s : %s\n", $_, $val);
			}
			close(F);			
		}

		if ($full){
			foreach (keys %$tags) {
				my $val = $$tags{$_};

				if (ref $val eq 'ARRAY') {
					$val = join(', ', @$val);
				} elsif (ref $val eq 'SCALAR') {
					$val = '(Binary data)';
				}
	
				printf("%-24s : %s\n", $_, $val);
			}
		}elsif ($tags->{decimallatitude}){
			printf("%-24s : %s\n", "Latitude:", $tags->{decimallatitude});
			printf("%-24s : %s\n", "Longitude:", $tags->{decimallongitude});
			printf("%-24s : %s\n", "Location:", $tags->{locationstring});
		}
	
		if ($tags->{Make}){
			printf("%-24s : %s\n", "Make:", $tags->{Make});
			printf("%-24s : %s\n", "Model:", $tags->{Model});
		}

	}else{
		print "No EXIF Tags :(\n";
	}

	$brute = Reaper::StringBrute($url_combo, $brute);

}
