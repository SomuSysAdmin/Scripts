#!/bin/bash

echo -e "Rearrange v1 Started..."
retry=true

while [ ${retry} ];
do
	echo -ne "Enter the name of the file: "
	read fileName
	echo -ne "Enter the file location: "
	read path
	echo -ne "Enter the file description: "
	read description

	echo -ne "Adding the details of $path/$fileName to README.md with the following detials: \n\n$description\n\nConfirm? (y/N): "
	read confirm

	if [ "$confirm" = "y" ]; then
		#Code for Confirm
		echo -e "Rearrangement Complete!"
		retry=false;
	else
		echo -ne "Re-enter details? (y/N): "
		read retry
		if [ $retry = "y" ]; then
			retry=true
		else
			retry=false
			echo -e "Rearrangement Cancelled!"
		fi
	fi
done
