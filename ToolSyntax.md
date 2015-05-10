# Introduction #

There are two tools available:
  * reap.pl - Analyzes a specific photo at a URL
  * stalk.pl - Analyzes each photo in a user's photo stream

# reap.pl #
reap.pl analyzes a single photo at one of the supported photo services, looks for location related EXIF tags ("geo-tags") and displays the location or displays all the EXIF tags.

## Syntax ##
`reap.pl <url> [--full] [--debug]`

Where URL is a URL to a photo of one of the supported photo services:
  * TwitPic
  * YFrog
  * MobyPicture
  * Flickr _(Only flic.kr URLs supported)_
  * Sexypeek

By default, reap.pl will check for geo-tag information only. If _--full_ is given on the command line, reap.pl will print out all EXIF tags embedded in the photo. Running reap.pl with the _--debug_ flag will cause reap.pl to print some diagnostic information.

# stalk.pl #
stalk.pl analyzes a each photo in a user's photostream at one of the supported photo services and looks for location related EXIF tags ("geo-tags"). If found, it displays the location or outputs it to a KML file.

## Syntax ##
`stalk.pl --username=<target_user> --service=<service> [--output=(kml|text)] [--endpage=<last_page>] [--debug]`

Where the username is the target username and the service is one of the supported photo services:
  * TwitPic
  * YFrog

By default, stalk.pl will output the results to the console in text. If _--output=kml_ is given on the command line, stalk will write a file [KML](https://secure.wikimedia.org/wikipedia/en/wiki/Keyhole_Markup_Language) file in the local directory called (username)_output.kml. Also, stalk.pl will index the user's entire photostream, specifying_--endpage_with a number will tell it to stop after the specified number of photo pages. (_Please note, there will be more then one photo per index page. This depends on the target user's settings and photo service_). Running it with the_--debug