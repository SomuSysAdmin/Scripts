#!/bin/bash

### Shows UUID of input /dev's - REQUIRES SUDO

## Options:
## [-m]	Multiple Devs 	- returns both dev name and UUID
## [  ] No option	- returns only the UUID of the dev.

if [ "$#" = "0" ]; then
	echo "Enter -m flag for multiple, or no flag for single dev UUID. Follow with sda numbers."
	echo "	Usage:	./dUShow.sh [-m] (sda#) -->	./dUShow.sh -m 3 5 
					OR 	./dUShow.sh 3"
	exit #?
elif [ "$#" = "1" ]; then
	sudo blkid | grep .*sda[$1] | sed -r 's/.* UUID="([[:alnum:]]+)".*/\1/g'
fi

while getopts m: option
do
	case "${option}"
	in
	m)	echo -e "\nDEV\tUUID\n====\t================"
		regex=".*sda($( IFS='|'; echo "$*" ))\\>";
		blkid | grep -E $regex | sed -r 's/\/dev\/([[:alnum:]]+).* UUID="([[:alnum:]]+)".*/\1\t\2/g'
		echo 
		;;
	esac
done
