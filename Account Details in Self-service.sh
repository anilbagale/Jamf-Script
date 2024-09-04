#!/bin/bash


curUser=$(ls -l /dev/console | cut -d " " -f 4)
loggedInUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }' )
loggedInUserFullname=$( id -F "${loggedInUser}" )
loggedInUserFirstname=$( echo "$loggedInUserFullname" | sed -E 's/^.*, // ; s/([^ ]*).*/\1/' | sed 's/\(.\{25\}\).*/\1…/' | awk '{print toupper(substr($0,1,1))substr($0,2)}' )

# Client ID and secret used to authenticate to the Jamf Pro API
# ONLY needs the "Read" privilege for the "Computer" object and nothing else
client_id='bd1ed063-e48b-40fd-a03c-a6caa10f2e87'
client_secret='86PGym6Se33acR8q0YS6wEqdLX--tAL33LPrkzUPi3S06DqmdwYDihd_aL6YRWnE'
jamf_pro_url='https://iqvia.jamfcloud.com'

# ---------- SCRIPT LOGIC BELOW - DO NOT MODIFY ---------- #

# Get the computer's serial number
serial_number=$(system_profiler SPHardwareDataType | awk '/Serial Number/{print $4}')

# Get an access token based on the client ID and secret above
token_response=$(curl --silent --location --request POST "${jamf_pro_url}/api/oauth/token" \
  --header "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "client_id=${client_id}" \
  --data-urlencode "grant_type=client_credentials" \
  --data-urlencode "client_secret=${client_secret}")

access_token=$(echo "$token_response" | plutil -extract access_token raw -)

# Pull down the inventory record and extract the "phone" attribute, which is the "lastPasswordChangeDateTime" attribute
inventory_response=$(curl -sX GET "${jamf_pro_url}/JSSResource/computers/serialnumber/${serial_number}" \
  --header "Authorization: Bearer ${access_token}" \
  --header "Accept: application/xml")

# Extract the "phone" attribute from the response
lastPasswordChangeDateTime=$(xmllint --xpath '//computer/location/phone_number/text()' - <<<"$inventory_response")

# Format the date for the extension attribute and for it to be used as a date criteria in a smart groups
formattedDate=$(date -j -u -f "%Y-%m-%dT%H:%M:%SZ" "$lastPasswordChangeDateTime" "+%Y-%b-%d")

# Ensure lastPasswordChangeDateTime is parsed correctly
newDate=$(date -j -u -v+90d -f "%Y-%m-%dT%H:%M:%SZ" "$lastPasswordChangeDateTime" "+%Y-%m-%d")

passnewDate=$(date -j -u -v+90d -f "%Y-%m-%dT%H:%M:%SZ" "$lastPasswordChangeDateTime" "+%Y-%b-%d")

# Get the current date in the same format
currentDate=$(date "+%Y-%m-%d")

# Calculate the difference in days between the expiration date and the current date
# Convert dates to seconds since the epoch, then find the difference in days
remainingDays=$(( ($(date -jf "%Y-%m-%d" "$newDate" +%s) - $(date -jf "%Y-%m-%d" "$currentDate" +%s)) / 86400 ))

#PSSO registered account
PSSO=$(dscl . read /Users/$loggedInUser dsAttrTypeStandard:AltSecurityIdentities | awk -F'SSO:' '/PlatformSSO/ {print $2}')

# Check if the date calculation is negative, and adjust accordingly
if [ "$remainingDays" -lt 0 ]; then
  remainingDays=0
fi


jamfHelper="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"
windowType="hud"
description="Hello $loggedInUserFirstname

Platform SSO registered account is: $PSSO
Password last changed: $formattedDate
Password will expire: $passnewDate
Days until the password expires: $remainingDays


."

button1="OK"
title="Entra Account Details"
alignDescription="left"
alignHeading="center"
defaultButton="1"
timeout="86400"
icon="/Users/Shared/IQforpass.webp"

# JAMF Helper window as it appears for targeted computers
userChoice=$("$jamfHelper" -windowType "$windowType" -lockHUD -title "$title" -timeout "$timeout" -defaultButton "$defaultButton" -icon "$icon" -description "$description" -alignDescription "$alignDescription" -alignHeading "$alignHeading" -button1 "$button1")

