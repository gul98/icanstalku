#!/usr/bin/perl
#
# Reaper.pm
#
# A perl package that assists in various functions related to analysis 
# of location related EXIF tags ("geo-tags") 
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

package Reaper;

use Image::ExifTool qw(:Public);
use Geo::GeoNames;
use LWP::UserAgent;

my $ua = new LWP::UserAgent;
$ua->agent("Mozilla/5.0 (compatible; AppSecStreetFighter; PaulDotCom Security Weekly Rules; All Your GeoTags Are Belong To Us)");

sub GetTags($){

	my $file = shift;

	my $info = ImageInfo($file);

	if ($info->{GPSLatitude}){

		$info->{GPSLatitude} =~ /(\d+) deg (\d+)\' ([\d\.]+)\" ([NS])/;
		$latdec = $1;
		$latdec = $latdec + ($2/60);
		$latdec = $latdec + ($3/3600);

		if ($4 eq "S"){
			$longdec = -$longdec;
		}

		$info->{GPSLongitude} =~ /(\d+) deg (\d+)\' ([\d\.]+)\" ([EW])/;
		$longdec = $1;
		$longdec = $longdec + ($2/60);
		$longdec = $longdec + ($3/3600);

		if ($4 eq "W"){
			$longdec = -$longdec;
		}
		
		$info->{decimallatitude} = $latdec;
		$info->{decimallongitude} = $longdec;

		my $geo = new Geo::GeoNames();

		my $result = $geo->find_nearest_address(lat => $latdec, lng => $longdec);
		if ($result->[0] && ref($result->[0]->{placename}) ne "HASH"){
			if(ref($result->[0]->{street}) eq "HASH"){
				$info->{locationstring} = $result->[0]->{placename} . " " . $result->[0]->{adminCode1};
			}elsif (ref($result->[0]->{streetNumber}) eq "HASH"){
				$info->{locationstring} = $result->[0]->{street} . " " . $result->[0]->{placename} . " " . $result->[0]->{adminCode1};
			}else{
				$info->{locationstring} = $result->[0]->{streetNumber} . " " . $result->[0]->{street} . " " . $result->[0]->{placename} . " " . $result->[0]->{adminCode1};
			}
		}else{

			$result = $geo->find_nearby_placename(lat => $latdec, lng => $longdec);
	
			if ($result->[0]){ 
				$info->{locationstring} = $result->[0]->{name} . " " . $result->[0]->{countryName};

			}
		}
	
		return $info;

	}else{
		return 0;
	}

}

sub DownloadImage($){

	my $picture_url = shift;
	
	if ($picture_url =~ /(http\:\/\/(www\.|)twitpic\.com\/[\w\d]+)/i){
		my $service = 'twitpic';
		my $url = $1;
		print $1 . " - " if $debug; 

		$url =~ /twitpic\.com\/([\w\d]+)/;
		$fname = $1;
	
		@regexes = ('src=\"(http:\/\/web[0-9]+\.twitpic.com\/img\/.+\-full\.jpg[^"]*)"', 'src="(http:\/\/s3.amazonaws.com\/twitpic\/photos\/full\/[0-9]+.jpg[^"]*)"');

		return FindPicture($url . "/full", \@regexes);
		

	} elsif($picture_url =~ /(http:\/\/(www.|)yfrog\.com\/[\w\d]+)/i) {
		my $service = 'yfrog';
		my $url = $1;
		print $1 . " - " if $debug; 

		$url =~ /yfrog\.com\/([\w\d]+)/i;
		$fname = $1;

		@regexes = ('href=\"(http:\/\/img\d+\.yfrog\.com\/img\d+\/\d+\/[\w\d]+\.jpg)');

		return FindPicture($url, \@regexes);		

	} elsif($picture_url =~ /http:\/\/(www.|)sexypeek\.com\/([\w\d]+)/i) {
		my $service = 'sexypeek';
		my $url;
		my $fname = $2;

		if ($fname =~ /^f/){
			$url = "http://www.sexypeek.com/" . $fname;
			$fname =~ s/^f//;
		}else{
			$url = "http://www.sexypeek.com/f" . $fname;		
		}

		@regexes = ('img src="(\/img\/original\/Photo\/[\w\d\.]+\.jpg)');

		return FindPicture($url, \@regexes);

	} elsif($picture_url =~ /http:\/\/(www.|)twitsexy\.com\/(\d+)/i) {
		my $service = 'twitsexy';
		my $url;
		my $fname = $2;

		$url = "http://www.twitsexy.com/" . $fname;

		@regexes = ('viewimg.php\?height=\d+\&width=\d+\&image\=(\/images\/\w+\.jpg)');

		return FindPicture($url, \@regexes);

	} elsif($picture_url =~ /(http:\/\/(www.|)mobypicture\.com\/user\/.+\/view\/\d+)/i) {
		my $service = 'mobypicture';
		my $url = $1;
		print $1 . " - " if $debug; 

		$url =~ /mobypicture\.com\/user\/[\w\d]+\/view\/(\d+)/i;
		$url .= '/sizes/full';
		$fname = $1;
		@regexes = ('src=\"(http:\/\/img\.mobypicture\.com\/\w+\.jpg)\"');
		return FindPicture($url, \@regexes);	

	} elsif($picture_url =~ /(http:\/\/(www.|)flic\.kr\/p\/\w+)/i) {
		#http://flic.kr/p/8eSLJR
		my $service = 'flickr';
		my $url = $1;
		print $1 . " - " if $debug; 

		$url =~ /flic\.kr\/p\/(\w+)/i;
		$url .= '/sizes/o/in/photostream';
		$fname = $1;

		@regexes = ('src="http:\/\/farm\d\.static\.flickr\.com/\w+/[\w_]+\.jpg\"');

		return FindPicture($url, \@regexes);	


	} else {
		warn "I don't know how to process " . $picture_url . "\n";
		return 0;
	}
}

sub FindPicture($@){

	my ($url, $temp) = @_;

	@picture_regexes = @$temp;

	my $req = new HTTP::Request GET => $url;
	my $res = $ua->request($req);	

	if ( $res->is_success ) {
		foreach $picture_regex (@picture_regexes){
			if ($res->content =~ m/${picture_regex}/) {

				my $image_url = $1;

				if ($image_url !~ /^http/){
					$url =~ /(http\:\/\/[\w\.]+)\//;
					$image_url = $1 . $image_url;
				}

				$req = new HTTP::Request GET => $image_url;
				$res = $ua->request($req);
				if ( $res->is_success ) {
					return $res->content;
				}else{
					warn ("FAILED Getting Full Picture - " . $res->status_line);
					return 0;
	   			}
			}
		}

		warn "No JPEG Found";
		return 0;	

	} else {
		warn ("Bad URL ($url) - Returned " . $res->status_line);
		return 0;
	}
}

sub WriteToKML($@){

	my ($file, $temp) = @_;
	@locations = @$temp;

	open(FILE,">$file") or die("Unable to write to $file!");

	print FILE '<?xml version="1.0" encoding="UTF-8"?>' . "\n";
	print FILE '<kml xmlns="http://www.opengis.net/kml/2.2">' . "\n";
	print FILE "\t<Document>\n";

	foreach $location (@locations){
		print FILE "\t\t<Placemark>\n";
		print FILE "\t\t\t<name>" . $location->{url} . "</name>\n";
		print FILE "\t\t\t<description>\n";
		print FILE "\t\t\t\t<![CDATA[\n";
		if ($location->{thumb}){
			print FILE "\t\t\t\t\t<p><img src=\"".  $location->{thumb}  ."\"></p>\n";
		}
		print FILE "\t\t\t\t\t<p><a href=\"".  $location->{url}  ."\">Link</a></p>\n";
		print FILE "\t\t\t\t\t<p>" . $location->{locationstring} . "</p>\n";
		print FILE "\t\t\t\t]]>\n";
		print FILE "\t\t\t</description>\n";
		print FILE "\t\t\t<Point>\n";
		print FILE "\t\t\t\t<coordinates>" . $location->{decimallongitude} . "," . $location->{decimallatitude}  . "</coordinates>\n";
		print FILE "\t\t\t</Point>\n";
		print FILE "\t\t</Placemark>\n";

		print "OK!\n";
	}

	print FILE "\t</Document>\n";
	print FILE "</kml>\n";

}

sub StringBrute($$){
 
	my ($text, $curr_iteration) = @_;

	my $curr_iteration_length = length($curr_iteration);
	my $next_iteration = "";

	my @possible_text = split(//, $text);	

	if ($curr_iteration eq $possible_text[-1] x $curr_iteration_length) {
		$next_iteration = $possible_text[0] x ($curr_iteration_length + 1);
	}else{

		my @ginzu = split(//, $curr_iteration);
  		my $position = @ginzu - 1;
    
		while ($position >= 0){
		
			if($ginzu[$position] eq $possible_text[-1]){
				$ginzu[$position] = $possible_text[0];
				$position--;
			}else{
				my $i = 0;
				while ($i <= @possible_text){
					if($ginzu[$position] eq $possible_text[$i]){
						last;
					}
					$i++;
				}

				$ginzu[$position] = $possible_text[$i + 1];
				last;
			}

		}
  
		$next_iteration = join("", @ginzu);

	}

	return $next_iteration;
}
