#!/bin/bash -v

#gets current logged in user
consoleuser=$(ls -l /dev/console | cut -d " " -f4)

APP_NAME="Asana.app"
APP_PATH="/Applications/$APP_NAME"


DOWNLOAD_URL="https://desktop-downloads.asana.com/darwin_x64/prod/latest/Asana.dmg"
finalDownloadUrl=$(curl "$DOWNLOAD_URL" -s -L -I -o /dev/null -w '%{url_effective}')
dmgName=$(printf "%s" "${finalDownloadUrl[@]}" | sed 's@.*/@@')
AsanaDmgPath="/tmp/$dmgName"

################################

#downloads latest version of Slack
curl -L -o "$AsanaDmgPath" "$finalDownloadUrl"

#mount the .dmg
hdiutil attach -nobrowse $AsanaDmgPath

#Copy the update app into applications folder
sudo cp -R /Volumes/Asana/Asana.app /Applications

#unmount and eject dmg
#mountName=$(diskutil list | grep Docker | awk '{ print $3 }')
umount -f /Volumes/Asana/
diskutil eject $mountName

#clean up /tmp download
rm -rf "$AsanaDmgPath"

#Docker permissions
chown -R $consoleuser:admin "/Applications/Asana.app"
