#!/bin/bash

#File Date
getDateAndTime=$(date "+%a_%b-%d-%Y_%H-%M-%S")

	# Set Local Information
	status=0
	build="$4"
	build_version="$5"
	current_date=$(date +"%Y-%m-%d %T")
	tattoo_plist="/usr/local/MacMD/MacMD.plist"
	
	os_ver=$(/usr/bin/sw_vers -productVersion)
	os_minor_ver=$( /usr/bin/sw_vers -productVersion | /usr/bin/cut -d. -f2 )


	# Get Local Info
	logBannerDate=`date +"%Y-%b-%d %T"`
		
	##########################################################################################
	#	MAIN SCRIPT
	##########################################################################################
	
	
	echo " "
	echo "##########################################################################################"
	echo "#                                                                                        #"
	echo "#                      IQVIA Tattoo of the Mac - $logBannerDate                    #"
	echo "#                                                                                        #"
	echo "##########################################################################################"
	echo "IQVIA Tattoo of the Mac has Started..."
	

	# Get serial of this Mac
	echo "Finding the Serial number of the Mac."
	serial_num=$(ioreg -l | awk '/IOPlatformSerialNumber/ { split($0, line, "\""); printf("%s\n", line[4]); }')
	echo "We found that the Serial number of the Mac is: ${serial_num}"
	
	
	# Write .plist file
	echo "Writing Build key with a value of ${build} to ${tattoo_plist}"	
	defaults write "${tattoo_plist}" "Build" -string "${build}"
	status=$?
	
	echo "Writing Build Version key with a value of ${build_version} to ${tattoo_plist}"
	defaults write "${tattoo_plist}" "BuildVer" -string "${build_version}"
	status=$?
	
	echo "Writing Build Date key with a value of ${current_date} to ${tattoo_plist}"
	defaults write "${tattoo_plist}" "BuildDate" -string "${current_date}"
	status=$?

	echo "Writing Build OS key with a value of ${os_ver} to ${tattoo_plist}"
	defaults write "${tattoo_plist}" "BuildOS" -string "${os_ver}"
	status=$?

	echo "Writing Site key with a value of ${site} to ${tattoo_plist}"
	defaults write "${tattoo_plist}" "Site" -string "${site}"
	status=$?

	echo "Writing Entity key with a value of ${entity} to ${tattoo_plist}"
	defaults write "${tattoo_plist}" "Entity" -string "${entity}"
	status=$?

exit