#!/bin/sh

#identify user
user=$(stat -f %Su "/dev/console")

#Remove rights from identified user
dseditgroup -o edit -d $user -t user admin

echo "admin rights removed for $user"
