#!/bin/bash

# Script to download, Silent Install and then clean up once installed Microsft Teams

#Make temp folder for downloads.
mkdir "/tmp/teams/";
cd "/tmp/teams/";

#Download Teams.
curl -L -o /tmp/teams/Teams_osx.pkg "https://go.microsoft.com/fwlink/?linkid=2249065";

#install Teams
sudo installer -pkg /private/tmp/teams/Teams_osx.pkg -target /;

#tidy up
sudo rm -rf "/tmp/teams";

exit 0
