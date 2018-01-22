#!/bin/bash

# Default Values
sortDir="/vm/markdown_notes/_posts"

while getopts ":d:" opt; do	# -h doesn't use an argument
	case $opt in
		d)	sortDir="$OPTARG"
		;;
		\?)	echoErr "Invalid option -$OPTARG"
        ;;
	esac
done

#------------------------------------------    Custom Functions    -----------------------------------------------------
# Getting proper sortable values
function sortArr() {
    sortedArr=("$@")
    idx=0
    for id in "${sortedArr[@]}"
    do
        mod=$(echo "$id" | sed -E "s|([[:digit:]]+)\.([[:digit:]]+)\.([[:digit:]]+)|\1|g")
        chp=$(echo "$id" | sed -E "s|([[:digit:]]+)\.([[:digit:]]+)\.([[:digit:]]+)|\2|g")
        les=$(echo "$id" | sed -E "s|([[:digit:]]+)\.([[:digit:]]+)\.([[:digit:]]+)|\3|g")
        sortedArr[$idx]=$(( mod*10000 + chp*100 + les ))
        idx=$(( idx + 1 ))
    done
    sortedArr=($(echo "${sortedArr[@]}" | tr ' ' '\n' | sort -n))
    # Reverting back to original values in sorted order.
    idx=0
    for id in "${sortedArr[@]}"
    do
        mod=$(( $id/10000 ))
        id=$(( $id - mod*10000 ))
        chp=$(( $id/100 ))
        id=$(( $id - chp*100 ))
        les=$id
        sortedArr[$idx]="$mod.$chp.$les"
        idx=$(( idx + 1 ))
    done
    echo -e "${sortedArr[@]}"
}

#---------------------------------------------    End Functions    -----------------------------------------------------

sortedID=($(grep 'lessonID' "$sortDir"/* | sed -E "s|.*lessonID : (.*)|\1|g"))
sortedID=($(sortArr "${sortedID[@]}"))

for id in "${sortedID[@]}"
do
    files[$idx]=$(grep -x ".*lessonID : $id" "$sortDir"/* | sed -E "s|(.*):.*lessonID.*|\1|g")
    idx=$(( idx+1 ))
done
out=$(echo "${files[@]}" | tr ' ' '\n')
echo -e "$out"
