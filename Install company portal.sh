#!/bin/bash

# URL of the latest Company Portal installer
URL="https://officecdn.microsoft.com/pr/C1297A47-86C4-4C1F-97FA-950631F94777/MacAutoupdate/CompanyPortal-Installer.pkg"

# Download location
DOWNLOAD_PATH="/tmp/CompanyPortal-Installer.pkg"

echo "Downloading the latest Company Portal installer..."
curl -L -o "$DOWNLOAD_PATH" "$URL"

if [ $? -ne 0 ]; then
    echo "Failed to download the installer."
    exit 1
fi

echo "Installing Company Portal..."
sudo installer -pkg "$DOWNLOAD_PATH" -target /

if [ $? -eq 0 ]; then
    echo "Company Portal installed successfully!"
else
    echo "Installation failed."
    exit 1
fi

# Clean up
rm "$DOWNLOAD_PATH"

sudo jamf recon
