#!/bin/bash
# Guess I'm putting a license in
# Licensed under the Apache License, Version 2.0 (the "License");  you may not use this file except in compliance with the License.
# You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.
# Not intended for prod ¯\_(ツ)_/¯

# -- Modified from Script originally published at https://gist.github.com/opragel/bda5626c3b13c3fe5467
# -- * TEST TEST TEST!! * -- Noone is claiming this to be a "production ready" script... test and tweak to your needs!


# Comment any download url below to skip install #
DOWNLOAD_URLS=( \
  # Microsoft 365 BusinessPro Suite Installer
  "https://go.microsoft.com/fwlink/?linkid=2093504" \
  )

MAU_PATH="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app"
SECOND_MAU_PATH="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/Microsoft AU Daemon.app"
INSTALLER_TARGET="LocalSystem"

syslog -s -l error "MSEDGE - Starting Download/Install sequence."

for downloadUrl in "${DOWNLOAD_URLS[@]}"
do
  finalDownloadUrl=$(curl "$downloadUrl" -s -L -I -o /dev/null -w '%{url_effective}')
  pkgName=$(printf "%s" "${finalDownloadUrl[@]}" | sed 's@.*/@@')
  pkgPath="/tmp/$pkgName"
  syslog -s -l error "MSEDGE - Downloading %s\n" "$pkgName"

  # modified to attempt restartable downloads and prevent curl output to stderr
  until curl --retry 1 --retry-max-time 180 --max-time 180 --fail --silent -L -C - "$finalDownloadUrl" -o "$pkgPath"; do
    # Retries if the download takes more than 3 minutes and/or times out/fails
  	syslog -s -l error "MSEDGE - Preparing to re-try failed download: %s\n" "$pkgName"
    sleep 10
  done
  syslog -s -l error "MSEDGE - Installing %s\n" "$pkgName"
  # run installer with stderr redirected to dev null
  installerExitCode=1
  while [ "$installerExitCode" -ne 0 ]; do
    sudo /usr/sbin/installer -pkg "$pkgPath" -target "$INSTALLER_TARGET" > /dev/null 2>&1
    installerExitCode=$?
    if [ "$installerExitCode" -ne 0 ]; then
      syslog -s -l error "MSEDGE - Failed to install: %s\n" "$pkgPath"
      syslog -s -l error "MSEDGE - Installer exit code: %s\n" "$installerExitCode"
    fi
  done
  rm "$pkgPath"

done


# -- Modified from Script originally published at https://gist.github.com/erikng/7cede5be1c0ae2f85435
syslog -s -l error "MSEDGE - Registering Microsoft Auto Update (MAU)"
if [ -e "$MAU_PATH" ]; then
  /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -R -f -trusted "$MAU_PATH"
  if [ -e "$SECOND_MAU_PATH" ]; then
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -R -f -trusted "$SECOND_MAU_PATH"
  fi
fi

syslog -s -l error "MSEDGE - SCRIPT COMPLETE"