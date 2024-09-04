#!/bin/bash

#Create API client and API Role in jamf pro > Settings > System > API roles and clients.
#change value in the script
#####"client_id"  
#####"client_secret"
#####"jamf_pro_url"
#####"group_id" - Static group ID

client_id='client_id here'
client_secret='client_secret here'
jamf_pro_url='https://companyname.jamfcloud.com'
JAMF_BINARY="/usr/local/bin/jamf"
serialNumber=$(system_profiler SPHardwareDataType | awk '/Serial/ {print $4}')
group_id='XXX'

# Do not change anything below in this script.
# Get an access token based on the client ID and secret above
token_response=$(/usr/bin/curl --silent --location --request POST "${jamf_pro_url}/api/oauth/token" \
  --header "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "client_id=${client_id}" \
  --data-urlencode "grant_type=client_credentials" \
  --data-urlencode "client_secret=${client_secret}")

access_token=$(echo "$token_response" | plutil -extract access_token raw -)

xmlData="<computer_group>
  <computer_additions>
    <computer>
      <serial_number>$serialNumber</serial_number>
    </computer>
  </computer_additions>
</computer_group>"

# Remove device from Static groups
/usr/bin/curl -X PUT "${jamf_pro_url}/JSSResource/computergroups/id/$group_id" \
  -H "Authorization: Bearer $access_token" \
  -H "Content-Type: application/xml" \
  --data "$xmlData"
