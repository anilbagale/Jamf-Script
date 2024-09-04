#!/bin/bash

# Script to download, Silent Install and then clean up once installed Microsft Teams

#Make temp folder for downloads.
mkdir "/tmp/teams/";
cd "/tmp/teams/";

#Download Teams.
curl -L -o /tmp/teams/Teams_osx.pkg "https://go.microsoft.com/fwlink/p/?LinkID=869428&clcid=0x4009&culture=en-in&country=IN&lm=deeplink&lmsrc=groupChatMarketingPageWeb&cmpid=directDownloadMac";

#install Teams
sudo installer -pkg /private/tmp/teams/Teams_osx.pkg -target /;

#tidy up
sudo rm -rf "/tmp/teams";

exit 0