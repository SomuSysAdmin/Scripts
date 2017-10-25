#!/bin/bash

### Outputs the total duration of video in each folder (recursively).
##	Incase an argument is not provided, the basefolder is assumed to be pwd.

# printf formatting style
printDotsN() {
    # $1 is the text before dots, $2 is the text after dots, $3 and $4 are (optional) printing formats of $1 and $2 respectively! 
    if [ $# -le 3 ]; then
        # No priting formats
        p1=$(printf "%s" "$1")
        p2=$(printf "%s" "$2")
    elif [ $# -eq 3 ]; then
        # Only printing format for $1 is given
        p1=$(printf "$3" "$1")
        p2=$(printf "%s" "$2")
    else
        p1=$(printf "$3" "$1")
        p2=$(printf "$4" "$2")
    fi   

    cols=$(tput cols)
    offset=${#p1} # Returns length of string p1
    dots=$(( $cols - $offset ))
    vDots=$(printf "%*s" "$dots" "$p2")
    vDots=$(echo "$vDots" | perl -pe 's/ (?!\S)/./g')

    printf "%s%s\n" "$p1" "$vDots" 
}

echoErr() { 
    echo -e "${RED}[ERROR]${NC}: $@" 1>&2
    exit
}

folderTimeCalc() {
	echo $(find . -maxdepth 1 -iname '*.mp4' -exec ffprobe -v quiet -of csv=p=0 -show_entries format=duration {} \; | paste -sd+ -| bc)
}

timeFormat() {
	# Converts time in seconds to HH:MM:SS
	# $1 is the input parameter, return value is $fTime (formatted Time).
	fTime=0

	local sec=$(echo "$1/1 + 1" | bc)
	local min=$(echo $sec/60 | bc)
	sec=$(echo $sec%60 | bc)
	local hr=$(echo $min/60 | bc)
	min=$(echo $min%60 | bc)

	fTime=$(printf "%6d hrs : %02d mins : %02d secs" "$hr" "$min" "$sec")
}

# Setting the base directory
if [ "$#" -lt 1 ]; then
    baseDir="$(pwd)"
else
    baseDir="$1"
fi

cd "$baseDir" || echoErr "Error switching to $baseDir"

# Actual calculation of the total video duration in each folder - using a function.
totalTime=0
function calcTime() {
	local immediateTime=0
	local folderTime=0
	immediateTime=$(folderTimeCalc)
	folderTime=$immediateTime
	for f in "$1"/*
	do
		if [ -d "$f" ]; then
			cd "$f" || echoErr "Can't switch to $f" 
			local oldTime=$totalTime
			calcTime "$f"
			folderTime=$( echo "$folderTime + $totalTime - $oldTime" | bc)
		else
			continue
		fi
	done

	# Coloured output doesn't yet work. Will fix in free time.

	totalTime=$(echo "$totalTime + $immediateTime" | bc)
	name=$(echo "$1" | sed "s/.*\/\(.*\)/\1/")

	timeFormat $immediateTime
	timePrint=$(printf "(%10.2f s)" "$immediateTime")
	printDotsN "$name " " $fTime $timePrint"
	timeFormat $folderTime
	timePrint=$(printf "(%10.2f s)" "$folderTime")
	printDotsN "$name " " $fTime $timePrint"
	timeFormat $totalTime
	timePrint=$(printf "(%10.2f s)" "$totalTime")
	printDotsN "$name (& Subfolders) " "$fTime $timePrint" 
}
calcTime "$baseDir"
