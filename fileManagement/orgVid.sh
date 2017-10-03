#!/bin/bash

### Sorts videos of Pearson IT Certification - Red Hat Cert Sys Admin course by Sander Van Gurt.
##  No input required.
##  Uses the file name themselves, and a matching pattern to deduce which files belong in which directory.
##  Directories are themselves numbered 1 through 26.
##  A simple yet fast algo would be simply grepping the title for the integer part of a number and putting
##		it into the corresponding chapter's folder. Though, in case there is a need for a number in the file
##		name other than to simply indicate the chapter's order, this can cause obvious problems.

# Defining custom Constants & functions

RED='\033[1;31m'
NC='\033[0m' # No Color

echoErr() { 
	echo -e "${RED}[ERROR]${NC}: $@" 1>&2
	exit
}

# Setting the base directory
if [ "$#" -lt 1 ]; then
	baseDir="$(pwd)"
else
	baseDir="$1"
fi

cd "$baseDir" || echoErr "Error switching to $baseDir"

# Now finding each file and creating Module folders, Chapter sub-folders and finally placing the individual files
#	on the basis of that logic in the subfolders.

mod=""
les=""
counter=0

for f in "$baseDir"*; 
do
	[ "$f" = "$baseDir" ] && continue; 
	
	# Extraction of details from file name.
    newMod=$(echo "$f" | sed -nr "s/.*Module ([[:digit:]]+).*/\1/p")
    newLes=$(echo "$f" | sed -nr "s/.*Lesson ([[:digit:]]+).*/\1/p")	
	
	# Code for New Module detection.
	# Returns true if $newLes not empty and there is a new value for les.
    if [ ! -z "$newMod" ]; then
		[ ! -z "$newMod" ] && mod=$newMod
		counter=0;
		les=""
		folderName=$(echo "$f" | sed -r "s/.*[[:alnum:]]+ - (.*) -.*/\1/") 	# Obtaining the Module Name (sandwiched between -'s)
		[ ! -z $mod ] && folderName="$mod. $folderName"						# Adding the Module Number to the directory name.
		cd "$baseDir" || echoErr "Error switching to $baseDir"
		mkdir "$folderName" || echoErr "Error creating $folderName"
		cd "$folderName" || echoErr "Error switching to $folderName"
		echo "[$folderName]-->"

    elif [ ! -z "$newLes" ] && [ "$newLes" != "$les" ]; then
        if [ ! -z "$les" ]; then
			cd .. || echoErr "Error switching to parent directory" 			# Changes a directory upon completion of a lesson. Skips when new module is first entered.
			echo "<--cd 1 dir up!"
		fi

		les=$newLes
		counter=0
		folderName=$(echo "$f" | sed -r "s/.*[[:alnum:]]+ - (.*) -.*/\1/")			# Obtaining the Lesson Name (sandwiched between -'s)
		[ ! -z "$les" ] && folderName="$les. $folderName"	# Adding the Module & Lesson Number to the directory name.
		[ ! -z "$mod" ] && folderName="$mod.$folderName"	
		mkdir "$folderName" || echoErr "Error creating $folderName"
        cd "$folderName" || echoErr "Error switching to $folderName"
		echo "cd to [$folderName]-->"	
    fi

	# Actual file creation code
	fname=$(echo $f | sed -r "s/.*- ([[:digit:]]+\.[[:digit:]]+ )*(.*\.mp4)/\2/")	# Ignores the lesson number in original file name
	[ ! -z $les ] && fname="$les.$counter $fname"			# Adds the module and lesson number to the file name extracted above
	[ ! -z $mod ] && fname="$mod.$fname"

	if [ "$f" != "$fname" ]; then 
		mv "$f" "$fname" || echoErr "Couldn't move file $f or rename to $fname"
	fi

	echo -e "$fname"
	counter=$(($counter+1))
done
echo "Complete!"
