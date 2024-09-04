#!/bin/bash

Dialpad InstallerIT
-----------------------------------------------------------------------
	Written by: Anil Bagale

	
	Created: February 08, 2021
        Updated: February 08, 2021
	Purpose: Downloads and installs the latest available Dialpad
	app specified directly on the client. This avoids having to
	manually download and store an up-to-date installer on a
	distribution server every month.
	
-----------------------------------------------------------------------
ABOUT_THIS_SCRIPT


# this is the full URL
url="http://storage.googleapis.com/dialpad_native/osx/dialpad_dist.pkg"

# change directory to /private/tmp to make this the working directory
cd /private/tmp/

# download the installer package and name it for the linkID
/usr/bin/curl -JL "$url" -o "dialpad_dist.pkg"

# install the package
/usr/sbin/installer -pkg "dialpad_dist.pkg" -target /

# remove the installer package when done
/bin/rm -f "dialpad_dist.pkg"

exit 0
