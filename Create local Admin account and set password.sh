#!/bin/bash

#File Date
getDateAndTime=$(date "+%a_%b-%d-%Y_%H-%M-%S")

# To Capture output into Date and Time log file
	
		
		##########################################################################################
		#	Variables
		##########################################################################################
		
		# Admin Account Info
		admin_acct="MacMDAdmin" # use $4 for Prod
		comp_hash="@dm1n" # use $5 for Prod
		
		
		#Local info
		getComputerHostname=$( echo `hostname` | tr '[a-z]' '[A-Z]' )		
		logBannerDate=`date +"%Y-%b-%d %T"`
		retryEvery=30
		
		##########################################################################################
		#	MAIN SCRIPT
		##########################################################################################
		
		
		echo "##########################################################################################"
		echo "#                                                                                        #"
		echo "#                Add Local Admin Account Quintiles - $logBannerDate                #"
		echo "#                                                                                        #"
		echo "##########################################################################################"
		echo "IQVIA Create Local Admin Account has Started..."
		
		
		# Check passed Admin account name from JAMF
		echo "Getting the Admin Account Name from JAMF"
		if [ -z "${admin_acct}" ]; then
			echo "We were unable to determine Admin Account Name. We need to exit script."
			return 1
		else
			echo "We were able to determine Admin Account Name so we can continue."
		fi

		
		# Check passed hash variable from JAMF
		echo "Getting the password hash from JAMF"
		if [ -z "${comp_hash}" ]; then
			echo "We were unable to determine the password hash. We need to exit script."
			return 1
		else
			echo "We were able to determine password hash so we can continue."
		fi
		
		
		# Get computer name
		echo "We are finding the computer name."
		if [ -z "${getComputerHostname}" ]; then	
			echo "We were unable to find the computer name. We need to exit script."
			return 1
		else
			echo "We were able to find computer name of: ${getComputerHostname} so we can continue."
		fi
		
		
		# Create PW hash
		echo "we are generating Local Admin Password now."
		prefix="${getComputerHostname:0:6}"
		prefix_2="${getComputerHostname:8}"
		suffix="${comp_hash}"
        
		generatedPassword=("${prefix}${prefix_2}${suffix}")
        
		if [ -z "${generatedPassword}" ]; then	
			echo "We were unable to the Local Admin password. We need to exit script."
			return 1
		else
			echo "Local Admin password has been generated so we can continue."
		fi
	
		# Create admin account and set password
		echo "We are checking if admin exists on the computer."
		admin_exists=$(dscl . -list /Users | grep -w ${admin_acct})
        
		if [ -z "${admin_exists}" ]; then
			echo "The Admin account, ${admin_acct}, doesn't exist, so we can proceed with creating this account."
			echo "we are setting up the Local Admin account now."
            
			# Setup IQVIA User Account with DSCL
			echo "Starting setup of User:${admin_acct}"
			echo "Getting UniqueID of User:${admin_acct}"
			
			# Get Unique ID from DSCL
			getUniqueID=$(dscl . list /users UniqueID | awk '{print $2}' | sort -n | tail -1)
			
			lastUsedUniqueID=${getUniqueID}
			nextUniqueID="1"
			userUniqueID=$((${lastUsedUniqueID} + ${nextUniqueID}))
			
			
			# Get random Account Picture
			userPicturesPath="/Library/User Pictures/"
			randomUserPicturesPath=( $( ls "${userPicturesPath}" ) )
			randomFolder=$[$RANDOM % ${#randomUserPicturesPath[@]}]
			randomUserPictureFolder=${randomUserPicturesPath[$randomFolder]}
			completeUserPictureFolderPath="/Library/User Pictures/${randomUserPicturesPath[$randomFolder]}/"
			getRandomUserPicture=( $( ls "${completeUserPictureFolderPath}" ) )
			randomPicture=$[$RANDOM % ${#getRandomUserPicture[@]}]
			randomUserPicture=${getRandomUserPicture[$randomPicture]}
			completeUserPicture="${completeUserPictureFolderPath}${randomUserPicture}"
			
			
			# Create User Account
			echo "Creating User:${admin_acct}"
			dscl . -create /Users/${admin_acct}
			echo "Creating bash shell for User:${admin_acct}"
			dscl . -create /Users/${admin_acct} UserShell /bin/bash
			echo "Creating Real Name for User:${admin_acct}"
			dscl . -create /Users/${admin_acct} RealName "MacMD Admin"
			echo "Creating Primary Group for User:${admin_acct}"
			dscl . -create /Users/${admin_acct} PrimaryGroupID 20
			echo "Creating NFSHomeDirectory for User:${admin_acct}"
			dscl . -create /Users/${admin_acct} NFSHomeDirectory /Users/${admin_acct}
			echo "Creating Group Membership for User:${admin_acct}"
			dscl . -append /Groups/admin GroupMembership ${admin_acct}
			
			
			# Delete the hex entry for jpegphoto
			dscl . delete /Users/${admin_acct} jpegphoto
			dscl . delete /Users/${admin_acct} Picture
			dscl . create /Users/${admin_acct} Picture "${completeUserPicture}"
			
			
			# Set UniqueID for User
			echo "Creating UniqueID for User:${admin_acct}"
			dscl . -create /Users/${admin_acct} UniqueID ${userUniqueID}
			
			
			# Set User Password
			echo "Creating Password for User:${admin_acct}"
			dscl . -passwd /Users/${admin_acct} ${generatedPassword}
			
			# Create the home directory
			createhomedir -c
						
			echo "User Account:${admin_acct} is complete!"

            
			returnCode=$?
			
			if [ ${returnCode} -eq 0 ]; then
				echo "The Admin account, ${admin_acct}, was created successfully."
			else   
				echo "The Admin account, ${admin_acct}, was NOT created successfully. Error code: ${returnCode}. We need to exit script."
				return 1
                
			fi
            
		else
        
			echo "The Admin account, ${admin_acct}, already exists, we don't know the password so we will delete it and recreate it new."
			
			# Deleteing the duplicate admin account if it is here for some reason on new computer
			sysadminctl -deleteUser ${admin_acct}
			
			sleep 5
			
			# Checking if the account was deleted
			echo "We are checking if admin has been deleted correctly."
			admin_exists=$(dscl . -list /Users | grep -w ${admin_acct})
			
			if [ -z "${admin_exists}" ]; then
				echo "The Admin account, ${admin_acct}, doesn't exist, so we can proceed with creating this account."
				echo "we are setting up the Local Admin account now."
				
				# Setup IQVIA User Account with DSCL
				echo "Starting setup of User:${admin_acct}"4
				echo "Getting UniqueID of User:${admin_acct}"
				
				# Get Unique ID from DSCL
				getUniqueID=$(dscl . list /users UniqueID | awk '{print $2}' | sort -n | tail -1)
				
				lastUsedUniqueID=${getUniqueID}
				nextUniqueID="1"
				userUniqueID=$((${lastUsedUniqueID} + ${nextUniqueID}))
				
				
				# Get random Account Picture
				userPicturesPath="/Library/User Pictures/"
				randomUserPicturesPath=( $( ls "${userPicturesPath}" ) )
				randomFolder=$[$RANDOM % ${#randomUserPicturesPath[@]}]
				randomUserPictureFolder=${randomUserPicturesPath[$randomFolder]}
				completeUserPictureFolderPath="/Library/User Pictures/${randomUserPicturesPath[$randomFolder]}/"
				getRandomUserPicture=( $( ls "${completeUserPictureFolderPath}" ) )
				randomPicture=$[$RANDOM % ${#getRandomUserPicture[@]}]
				randomUserPicture=${getRandomUserPicture[$randomPicture]}
				completeUserPicture="${completeUserPictureFolderPath}${randomUserPicture}"
				
				
				# Create User Account
				echo "Creating User:${admin_acct}"
				dscl . -create /Users/${admin_acct}
				echo "Creating bash shell for User:${admin_acct}"
				dscl . -create /Users/${admin_acct} UserShell /bin/bash
				echo "Creating Real Name for User:${admin_acct}"
				dscl . -create /Users/${admin_acct} RealName "MacMD Admin"
				echo "Creating Primary Group for User:${admin_acct}"
				dscl . -create /Users/${admin_acct} PrimaryGroupID 20
				echo "Creating NFSHomeDirectory for User:${admin_acct}"
				dscl . -create /Users/${admin_acct} NFSHomeDirectory /Users/${admin_acct}
				echo "Creating Group Membership for User:${admin_acct}"
				dscl . -append /Groups/admin GroupMembership ${admin_acct}
				
				
				# Delete the hex entry for jpegphoto
				dscl . delete /Users/${admin_acct} jpegphoto
				dscl . delete /Users/${admin_acct} Picture
				dscl . create /Users/${admin_acct} Picture "${completeUserPicture}"
				
				
				# Set UniqueID for User
				echo "Creating UniqueID for User:${admin_acct}"
				dscl . -create /Users/${admin_acct} UniqueID ${userUniqueID}
				
				
				# Set User Password
				echo "Creating Password for User:${admin_acct}"
				dscl . -passwd /Users/${admin_acct} ${generatedPassword}
				
				# Create the home directory
				createhomedir -c > /dev/null
				
				
				echo "User Account:${admin_acct} is complete!"

				
				returnCode=$?
                
				if [ ${returnCode} -eq 0 ]; then
					echo "The Admin account, ${admin_acct}, was created successfully."
                    echo "${admin_acct} password is ${generatedPassword}"
                    echo "${prefix}"
                    echo "${prefix_2}"
                    echo "${suffix}"
				else   
					echo "The Admin account, ${admin_acct}, was NOT created successfully. Error code: ${returnCode}. We need to exit script."
					return 1
				fi
			fi
			
		fi	
exit
