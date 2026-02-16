#!/bin/sh

#identify user
user=$(stat -f %Su "/dev/console")

#Provide admin rights to identified user
dseditgroup -o edit -a $user -t user admin

echo "admin rights provided for $user"
