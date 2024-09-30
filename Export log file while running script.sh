#!/bin/bash

#File Date
getDateAndTime=$(date "+%a_%b-%d-%Y_%H-%M-%S")

#Build Logging for script
logFilePath="/var/log/MacMD" # Path to log file. Recommended /Library/Logs/"Company Name. also $7 can go here to use from jamf
logFile="$logFilePath/InstallRosetta.$getDateAndTime.log"
logFileDate=`date +"%Y-%b-%d %T"`

# Check if log path exists
if [ ! -d "$logFilePath" ]; then
	mkdir $logFilePath
	else
	echo Directory exist
fi

# Logging Script
function readCommandOutputToLog(){
	if [ -n "$1" ];	then
		IN="$1"
	else
		while read IN 
		do
			echo "$(date +"%Y-%b-%d %T") : $IN" | tee -a "$logFile"
		done
	fi
}

# Create function to catch error of script you are trying to run
function fail {
	echo $1 >&2
	break 
}

# Function to run the retry loop if there is an exit code with a failure with backoff delay.
function retry {
	local n=1
	local max=7
	local timeout=${TIMEOUT-15}
	while true; do
		"$@" && break || {
			if [[ $n -lt $max ]]; then
				((n++))
				echo "Command failed. Attempt $n/$max: Retrying in $timeout.." 1>&2
				sleep $timeout
				timeout=$(( timeout * 2 ))
				checkAndRefreshNetworkInterface
			else
				fail "The command has failed after $n attempts."
			fi
		}
	done
}

( # To Capture output into Date and Time log file
	
	function InstallRosetta {
	
	OLDIFS=$IFS

IFS='.' read osvers_major osvers_minor osvers_dot_version <<< "$(/usr/bin/sw_vers -productVersion)"

# restore IFS to previous state

IFS=$OLDIFS

# Check to see if the Mac is reporting itself as running macOS 11

if [[ ${osvers_major} -ge 11 ]]; then

  # Check to see if the Mac needs Rosetta installed by testing the processor

  processor=$(/usr/sbin/sysctl -n machdep.cpu.brand_string | grep -o "Intel")
  
  if [[ -n "$processor" ]]; then
    echo "$processor processor installed. No need to install Rosetta." 
  else

    # Check Rosetta LaunchDaemon. If no LaunchDaemon is found,
    # perform a non-interactive install of Rosetta.
    
    if [[ ! -f "/Library/Apple/System/Library/LaunchDaemons/com.apple.oahd.plist" ]]; then
        /usr/sbin/softwareupdate --install-rosetta --agree-to-license
       
        if [[ $? -eq 0 ]]; then
        	echo "Rosetta has been successfully installed."
        else
        	echo "Rosetta installation failed!"
        	exitcode=1
        fi
   
    else
    	echo "Rosetta is already installed. Nothing to do."
    fi
  fi
  else
    echo "Mac is running macOS $osvers_major.$osvers_minor.$osvers_dot_version."
    echo "No need to install Rosetta on this version of macOS."
fi
	}
	
	InstallRosetta
	
) 2>&1 | readCommandOutputToLog # To Capture output into Date and Time log file
