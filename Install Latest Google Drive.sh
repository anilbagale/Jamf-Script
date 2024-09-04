#!/bin/bash

Google Drive InstallerIT
-----------------------------------------------------------------------
	Written by: Anil Bagale

	
	Created: February 08, 2021
        Updated: February 08, 2021
	Purpose: Downloads and installs the latest available Dialpad
	app specified directly on the client. This avoids having to
	manually download and store an up-to-date installer on a
	distribution server every month.
	
-----------------------------------------------------------------------

# Script to download, Silent Install and then clean up once installed Google DrivE FileStream

#Make temp folder for downloads.
mkdir "/tmp/filestream/";
cd "/tmp/filestream/";

#Download filestream.
curl -L -o /tmp/filestream/GoogleDriveFileStream.dmg "https://dl.google.com/drive-file-stream/GoogleDriveFileStream.dmg";

#Mount, Install, and unmount GoogleDriveFileStream.dmg
hdiutil mount GoogleDriveFileStream.dmg;
sudo installer -pkg /Volumes/Install\ Google\ Drive/GoogleDrive.pkg -target "/Applications";
hdiutil unmount /Volumes/Install\ Google\ Drive;

#Tidy up
sudo rm -rf /tmp/filestream/
exit 0

