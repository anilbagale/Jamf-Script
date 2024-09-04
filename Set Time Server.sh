#!/bin/bash


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# VARIABLES
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

#File Date
getDateAndTime=$(date "+%a_%b-%d-%Y_%H-%M-%S")

int_time_svr="$4"
status=0

    ##########################################################################################
    #	MAIN SCRIPT
    ##########################################################################################
    
    
    echo " "
    echo "##########################################################################################"
    echo "#                                                                                        #"
    echo "#                      IQVIA set time Server - $logBannerDate                      #"
    echo "#                                                                                        #"
    echo "##########################################################################################"
    echo "Attempting to configure IQVIA  time servers for this client has started......"


    systemsetup -setusingnetworktime off
    systemsetup -setnetworktimeserver "${int_time_svr}"
    result=$?
    
    if [ $result -eq 0 ]; then
        echo "Client was successfully configured to use time server: ${int_time_svr}"
        touch /Users/Shared/Validation/Time/info.plist
    else
        echo "Unable to configure client to use time server: ${int_time_svr}. Error code: ${result}."
        status=1
    fi
    
    echo "server time.apple.com" >> /private/etc/ntp.conf
    result=$?
    
    if [ $result -eq 0 ]; then
        echo "Client was successfully configured to use time server: time.apple.com"
    else
        echo "Unable to configure client to use time server: time.apple.com. Error code: ${result}."
        status=1
    fi
    
    systemsetup -setusingnetworktime on
    
exit