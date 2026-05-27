#!/bin/bash

################################################################################
# JAMF FILEVAULT KEY VALIDATION + CSV VERIFICATION
################################################################################

# Jamf API credentials
client_id='JAMF PRO API CLIENT ID'
client_secret='JAMF PRO API CLIENT SECRET'
jamf_pro_url='https://ORGANISATION.jamfcloud.com'

# SMB Share Details
shareURL="//USERNAME:PASSWORD@NETWORK SHARED LOCATION FOLDER PATH"
mountPoint="/Volumes/FileVault_Keys"
csvFile="$mountPoint/filevault_keys.csv"

################################################################################
# MOUNT SMB SHARE
################################################################################

echo "Mounting SMB share..."

mkdir -p "$mountPoint"

mount_smbfs "$shareURL" "$mountPoint"

if [[ $? -ne 0 ]]; then
    echo "ERROR: Failed to mount SMB share"
    exit 1
fi

echo "SMB share mounted"

################################################################################
# GET SYSTEM DETAILS
################################################################################

serial_number=$(system_profiler SPHardwareDataType | awk '/Serial Number/{print $4}')
hostname=$(scutil --get ComputerName)
timestamp=$(date "+%Y-%m-%d %H:%M:%S")

echo "Serial Number: $serial_number"
echo "Hostname: $hostname"

################################################################################
# GET OAUTH TOKEN
################################################################################

echo "Getting Jamf API token..."

token_response=$(curl --silent --location --request POST "${jamf_pro_url}/api/oauth/token" \
  --header "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "client_id=${client_id}" \
  --data-urlencode "grant_type=client_credentials" \
  --data-urlencode "client_secret=${client_secret}")

access_token=$(echo "$token_response" | plutil -extract access_token raw - 2>/dev/null)

if [[ -z "$access_token" ]]; then
    echo "ERROR: Failed to get API token"
    umount "$mountPoint"
    exit 1
fi

echo "API token received"

################################################################################
# GET JAMF COMPUTER ID
################################################################################

computer_lookup=$(curl -s -X GET \
"${jamf_pro_url}/api/v1/computers-inventory?filter=hardware.serialNumber==$serial_number" \
  -H "Authorization: Bearer $access_token" \
  -H "Accept: application/json")

jamf_id=$(echo "$computer_lookup" | plutil -extract results.0.id raw - 2>/dev/null)

if [[ -z "$jamf_id" ]]; then
    echo "ERROR: Failed to get Jamf ID"
    umount "$mountPoint"
    exit 1
fi

echo "Jamf ID: $jamf_id"

################################################################################
# GET FILEVAULT RECOVERY KEY
################################################################################

inventory_response=$(curl -sX GET \
"${jamf_pro_url}/api/v1/computers-inventory/$jamf_id/filevault" \
  --header "Authorization: Bearer ${access_token}" \
  --header "accept: application/json")

recovery_key=$(echo "$inventory_response" | plutil -extract personalRecoveryKey raw - 2>/dev/null)

echo "FileVault Key: $recovery_key"

################################################################################
# VALIDATE RECOVERY KEY
################################################################################

if [[ -z "$recovery_key" || "$recovery_key" == "null" ]]; then
    echo "ERROR: Recovery key is empty"
    umount "$mountPoint"
    exit 1
fi

# Validate format
if [[ ! "$recovery_key" =~ ^([A-Z0-9]{4}-){5}[A-Z0-9]{4}$ ]]; then
    echo "ERROR: Invalid recovery key format"
    umount "$mountPoint"
    exit 1
fi

echo "Recovery key validated"

################################################################################
# CSV VALIDATION
################################################################################

# Create CSV if missing
if [[ ! -f "$csvFile" ]]; then
    echo "Creating CSV file..."
    echo "Hostname,Serial Number,Jamf ID,FileVault Key,Generated Date" > "$csvFile"
fi

################################################################################
# VERIFY EXISTING CSV ENTRY
################################################################################

echo "Checking existing CSV records..."

existing_records=$(grep ",$serial_number," "$csvFile")

# No record found
if [[ -z "$existing_records" ]]; then

    echo "Device not found in CSV"
    echo "Adding new entry..."

    echo "$hostname,$serial_number,$jamf_id,$recovery_key,$timestamp" >> "$csvFile"

else

    echo "Existing device record found"

    # Get latest record
    latest_record=$(echo "$existing_records" | tail -n 1)

    existing_hostname=$(echo "$latest_record" | cut -d',' -f1)
    existing_jamf_id=$(echo "$latest_record" | cut -d',' -f3)
    existing_key=$(echo "$latest_record" | cut -d',' -f4)

    ############################################################################
    # VERIFY RECOVERY KEY
    ############################################################################

    if [[ "$existing_key" == "$recovery_key" ]]; then

        echo "Recovery key already exists in CSV"

        # Verify hostname / Jamf ID
        if [[ "$existing_hostname" != "$hostname" ]] || [[ "$existing_jamf_id" != "$jamf_id" ]]; then

            echo "Hostname or Jamf ID changed"
            echo "Updating CSV with latest details..."

            echo "$hostname,$serial_number,$jamf_id,$recovery_key,$timestamp" >> "$csvFile"

        else
            echo "No changes detected"
        fi

    else

        echo "Recovery key changed"
        echo "Appending new record..."

        echo "$hostname,$serial_number,$jamf_id,$recovery_key,$timestamp" >> "$csvFile"

    fi
fi

################################################################################
# UNMOUNT SHARE
################################################################################

echo "Unmounting SMB share..."

umount "$mountPoint"

echo "Completed successfully"
exit 0
