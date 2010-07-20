#!/usr/bin/perl
#
# stalk.pl
#
# A perl script to analyze a user's photo stream for location related
# EXIF tags ("geo-tags") and output the location of each photo.
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
use LWP::Simple;
use Getopt::Long;

$|=1;

my ($service, $username, @pictures, $endpage, $output, @locations, $debug);
my ($index_base_url, $photo_base_url, $more_content, $url_regex);

my $page = 1;
my $endpage = 100; #I don't think anyone has that many pages of photos...
my $output = "text";

my $args = GetOptions (	"service=s" => \$service,
			"username=s" => \$username,
			"output=s" => \$output,
			"endpage=i" => \$endpage,
			"debug" => \$debug); 

my $error_condition = 0;

if (!$service){
	print localtime() . " Errr... Pretty cowardly not giving me a service...\n";
	$error_condition = 1;
}

if (!$username){
	print localtime() . " Errr... Pretty cowardly not giving me a username...\n";
	$error_condition = 1;
}

if (($output ne "text") && ($output ne "kml")){
	print localtime() . " Errr... I don't know how to output in '$output' format...\n";
	$error_condition = 1;
}


if ($error_condition) {
	die();
}


if ($service eq "twitpic"){
	$page = 1;
	$index_base_url = "http://www.twitpic.com/photos/$username?page=";
	$photo_base_url = "http://www.twitpic.com/";
	$more_content = '\"\>More photos';
	$url_regex = '\<a href="\/(\w+)"\>\<img src';

}elsif($service eq "yfrog"){
	$page = 0;
	$index_base_url = "http://yfrog.com/froggy.php?username=$username&page=";
	$photo_base_url = "http://yfrog.com/";
	$more_content = '">Next \d+<\/a><\/div>';
	$url_regex = '\<a href="http://yfrog.com/(\w+)"\>';

}else{
	print localtime() . " I don't know how to process the '$service' service.\n";
	die();	
}

my $done;

while((!$done) && ($page <= $endpage)){
	print localtime() . " Indexing $index_base_url" ."$page...\n";

	my $content = get($index_base_url . $page);
	
	if ($content !~ /${more_content}/){
		$done = 1;
	}

	my @lines = split("\n",$content);

	foreach(@lines){
		if(/$url_regex/){
			push(@pictures, $photo_base_url . $1);
		}
	}

	$page++;
}

if (@pictures < 1) {
	print localtime() . " I couldn't seem to find any pictures. Are you sure you got the service and username correct?\n";
	die();
}

print localtime() . " Begin the unnessecarily slow moving stalking mechanism!\n";

foreach(@pictures){

	print localtime() . " Grabbing $_ - ";

	$_ =~ /[\w\.]\/([\w\d]+)/i;
	my $filename = "./" . $username . "/" . $service . "_" . $1 . ".jpg";

	my $cached = -f $filename;
	my $picture;

	if(!$cached){
		$picture = Reaper::DownloadImage($_);
	}else{
		print "Cached... ";
		open FILE, $filename or die $!; 
		binmode FILE; my ($buf, $data, $n); 
		while (($n = read FILE, $data, 4) != 0) { 
			$picture .= $data; 
		}
		close FILE; 
	}


	if ($picture){

		if (!(-d "./" . $username)) {
			mkdir($username);
		}


		if(!$cached){
			open(F,">$filename");
			print F $picture;
			close F;
		}

		my $tags = Reaper::GetTags(\$picture);

		if($tags){
			$tags->{url} = $_;
			push (@locations, $tags);
			print "OK!\n";
		}else{
			print "Couldn't find Geotags :(\n";
		}

	}else{
		warn "FindPicture Fail!";
	}

}

print localtime() . " DING! Fries are done!\n";

if($output eq "kml"){
	Reaper::WriteToKML($username . "_" . $service . ".kml", \@locations);
}else{
	foreach my $location (@locations) {
		print "$location->{url} - Latitude: $location->{decimallatitude} Longitude: $location->{decimallongitude} - $location->{locationstring}\n";
	}
}

