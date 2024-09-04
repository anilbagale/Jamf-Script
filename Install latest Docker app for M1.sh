#!/bin/bash -v

#if you want slack to quit - in use with a jamf notifcation policy unhash next line
pkill Docker

#gets current logged in user
consoleuser=$(ls -l /dev/console | cut -d " " -f4)

APP_NAME="Docker.app"
APP_PATH="/Applications/$APP_NAME"


DOWNLOAD_URL="https://desktop.docker.com/mac/main/arm64/Docker.dmg?utm_source=docker&utm_medium=webreferral&utm_campaign=docs-driven-download-mac-arm64"
finalDownloadUrl=$(curl "$DOWNLOAD_URL" -s -L -I -o /dev/null -w '%{url_effective}')
dmgName=$(printf "%s" "${finalDownloadUrl[@]}" | sed 's@.*/@@')
DockerDmgPath="/tmp/$dmgName"

################################

#downloads latest version of Slack
curl -L -o "$DockerDmgPath" "$finalDownloadUrl"

#mount the .dmg
hdiutil attach -nobrowse $DockerDmgPath

#Copy the update app into applications folder
sudo cp -R /Volumes/Docker/Docker.app /Applications

#unmount and eject dmg
#mountName=$(diskutil list | grep Docker | awk '{ print $3 }')
umount -f /Volumes/Docker/
diskutil eject $mountName

#clean up /tmp download
rm -rf "$DockerDmgPath"

#Docker permissions
chown -R $consoleuser:admin "/Applications/Docker.app"
