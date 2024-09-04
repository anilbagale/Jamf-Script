#!/bin/bash

# Stop Tanium processes
sudo launchctl stop com.tanium.taniumclient

# Unload Tanium launch agent
sudo launchctl unload /Library/LaunchDaemons/com.tanium.taniumclient.plist

# Remove Tanium files and directories
sudo rm -rf /Library/Tanium
sudo rm -rf /Library/LaunchAgents/com.tanium.taniumclient.plist
sudo rm -rf /Library/LaunchDaemons/com.tanium.taniumclient.plist
sudo rm -rf /Library/PrivilegedHelperTools/com.tanium.taniumclient
sudo rm -rf /Library/Receipts/TaniumClient.pkg
sudo rm -rf /private/var/db/receipts/com.tanium.taniumclient.bom
sudo rm -rf /private/var/db/receipts/com.tanium.taniumclient.plist
rm /Library/LaunchDaemons/com.tanium.taniumclient.plist
rm /Library/LaunchDaemons/com.Tanium.tanium-client-upgrade.plist
rm /var/db/receipts/com.tanium.client.bom
rm /var/db/receipts/com.tanium.client.plist

echo "Tanium app has been uninstalled successfully."

sudo jamf recon
