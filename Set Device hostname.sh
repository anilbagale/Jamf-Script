#!/bin/bash

#File Date
getDateAndTime=$(date "+%a_%b-%d-%Y_%H-%M-%S")

#Build Logging for script
logFilePath="/var/log/MacMD" # Path to log file. Recommended /Library/Logs/"Company Name. also $7 can go here to use from jamf
logFile="$logFilePath/RenameComputer.$getDateAndTime.log"
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
	
	function RenameComputerQuintiles {
	
	#GET THE SERIAL NUMBER
	serial_num=$(ioreg -l | awk '/IOPlatformSerialNumber/ { split($0, line, "\""); printf("%s\n", line[4]); }')
	echo Device serial number is: ${serial_num}
	sitePrefix="ZTD"
	echo Site Prefix is: ${sitePrefix}

	FULLNAME=${sitePrefix}${serial_num}
	echo Setting up device name to: ${FULLNAME}

	#SET COMPUTER NAME
	/usr/sbin/scutil --set ComputerName "${FULLNAME}" | tr '[a-z]' '[A-Z]'
	/usr/sbin/scutil --set LocalHostName "${FULLNAME}" | tr '[a-z]' '[A-Z]'
	/usr/sbin/scutil --set HostName "${FULLNAME}" | tr '[a-z]' '[A-Z]'

	echo Device name change to: ${FULLNAME}
	} || exit 1
	
	retry RenameComputerQuintiles


) 2>&1 | readCommandOutputToLog # To Capture output into Date and Time log file
