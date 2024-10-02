#!/bin/bash

# Define the username of the local admin account you want to delete
admin_user="MacMDAdmin"

# Check if the user exists before attempting to delete it
if id "$admin_user" &>/dev/null; then
    # Disable the user account before deletion (optional)
    dscl . -create /Users/"$admin_user" UserShell /usr/bin/false
    
    # Kill all processes of the user (optional, but ensures a clean deletion)
    pkill -u "$admin_user"
    
    # Delete the user account and the user's home directory
    sysadminctl -deleteUser "$admin_user" -secure
    
    echo "User $admin_user deleted successfully."
else
    echo "User $admin_user does not exist."
fi

exit 0
