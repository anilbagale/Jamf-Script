#!/bin/bash

#File Date
getDateAndTime=$(date "+%a_%b-%d-%Y_%H-%M-%S")

#Build Logging for script
logFilePath="/var/log/MacMD" # Path to log file. Recommended /Library/Logs/"Company Name. also $7 can go here to use from jamf
logFile="$logFilePath/SetTimeServer.$getDateAndTime.log"
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
	
	function SetTimeServer {
	
# Desired NTP server
DESIRED_TIME_SERVER="10.56.254.254"

# Function to execute systemsetup commands silently
run_systemsetup() {
    sudo systemsetup "$@" 2>/dev/null
}

# Get current NTP server
current_time_server=$(run_systemsetup -getnetworktimeserver | awk '{print $4}')

# Get network time status
network_time_status=$(run_systemsetup -getusingnetworktime | awk '{print $3}')

# Enable network time if not enabled
if [ "$network_time_status" != "On" ]; then
    echo "Network time synchronization is disabled. Enabling it..."
    run_systemsetup -setusingnetworktime on
    if [ $? -ne 0 ]; then
        echo "Failed to enable network time synchronization."
        exit 1
    fi
else
    echo "Network time synchronization is already enabled."
fi

# Set the desired NTP server if it's not already set
if [ "$current_time_server" != "$DESIRED_TIME_SERVER" ]; then
    echo "Current NTP server is '$current_time_server'. Setting to '$DESIRED_TIME_SERVER'..."
    run_systemsetup -setnetworktimeserver "$DESIRED_TIME_SERVER"
    if [ $? -ne 0 ]; then
        echo "Failed to set network time server to '$DESIRED_TIME_SERVER'."
        exit 1
    fi
else
    echo "NTP server is already set to '$DESIRED_TIME_SERVER'."
fi

# Restart timed service silently
echo "Restarting timed service..."
sudo killall -HUP timed 2>/dev/null

# Confirm settings
echo "Current time server: $(run_systemsetup -getnetworktimeserver)"
echo "Network time status: $(run_systemsetup -getusingnetworktime)"
	}
	
	SetTimeServer
	
) 2>&1 | readCommandOutputToLog # To Capture output into Date and Time log file
