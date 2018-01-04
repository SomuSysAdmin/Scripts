#!/bin/bash

### Turns .LaTeX files to Markdown files (Github-Flavoured Markdown)

# Defining custom Constants & functions
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

## Error function
echoErr() {
	echo -e "${RED}[ERROR]${NC}: $@" 1>&2
	exit
}

## Echo with Color
echoCol() {
	# First param is color code as follows:
	# 	Red		- 1
	# 	Green	- 2
	# 	Blue	- 3
	# Next Two parameters are the text that has to be colored ($2) and the part that's not ($3).

	if [ $1 -eq 1 ]; then COL=$RED;
	elif [ $1 -eq 2 ]; then COL=$GREEN;
	elif [ $1 -eq 3 ]; then COL=$BLUE;
	elif [ $1 -eq 4 ]; then COL=$YELLOW;
	else echoErr "Color NOT found!"
	fi
	echo -e "${COL}$2${NC}$3"
}

# Setting the base directory
if [ "$#" -lt 1 ]; then
	baseDir="$(pwd)"
	copyDir="/vm/markdown_notes"
elif [ "$#" -lt 2 ]; then
	baseDir="$1"
	copyDir="/vm/markdown_notes"
else
	baseDir="$1"
	copyDir="$2"
fi

if [ "$3" = "--remove" ]; then
	echoCol "3" "WARNING: " "Deleted contents of $copyDir"
	rm -rf $copyDir/*
fi

echo "Basedir: $baseDir"
echo "Copydir: $copyDir"
subGroup=$(echo "$baseDir" | sed -E "s|.*\/(.*)|\1|g")
mkdir "$copyDir/$subGroup" || echoErr "Error creating directory $subGroup @ $copyDir"
echoCol 4 "Info: " "Created Directory ${BLUE}$copyDir/$subGroup${NC}"

# Copying all directories, and translating all files from LaTeX to Markdown using Pandoc
function traverse() {
	for f in "$1"/*;
	do
	    [ "$f" = "$1" ] && continue
		if [ -d "$f" ]; then
        	# echo "** Directory $f **"
			relpath=$(echo "$f" | sed -E "s|$baseDir||g")
			relpath="$subGroup$relpath"
			#echo "f = $f"
			#echo "Relpath = $relpath"
			location="$copyDir/$relpath"
			#echo "Copydir+Relpath = $location"
			location=$(echo "$location" | sed -E "s|(.*)/chapters(.*)|\1\2|g")
			#echo "Location = $location"
			mkdir "$location" || echo -e "${RED}ERROR:${NC} Can't create directory $location"
			echoCol 4 "Info: " "Created Directory ${BLUE}$location${NC}"
        	traverse "$f"
    	else
			# Making the Chapter Heading from file name :
			pre=$(numExt "$f")
			name=$(echo "$f" | sed -En "s/.*\/chapters\/([[:digit:]]+\.)([[:digit:]]+) (.*).tex/\3/pg")
			if [ -n "$name" ]; then # if a valid texfile within the `chapters` Directory is found
        		# echo "$f"
				# echoCol 3 "├─Prefix : " "$pre"
				name=$(echo "$name" | tr '/' '-')
				name=$(echo "Chapter $pre. $name")
				echoCol 2 "$name" ""
				#echo "$name"
				mkdir "$location/$name" || echoErr "Can't create directory $name @ $location"
				echoCol 4 "Info: " "Created Directory ${BLUE}$location/$name${NC}"

				# Analyzing File `$f` to find sections and name them :
				count=0
				echo -n "" > temp.tex 	# Clearing a temporary tex file to contain the passage.
				while read -r line
				do
					# Checking if the current line is a section.
				    head=$(echo -ne "$line" | sed -nE "s/\\\section\{(.*)\}/\1\n/gp")
			    	head=$(echo -n "$head" | sed -E "s/\\\_/_/g")
			    	head=$(echo -n "$head" | sed -E "s/\n//g")
					if [ -n "$head" ]; then
						[ -s temp.tex ] && mkGfm "$location/$name/$fullName"
						count=$(( $count+1 ))
						fullName="$count. $head"
						fullName=$(echo "$fullName" | tr '/' '-')
					    echoCol 4 "  $fullName" ""
					elif [ $count -gt 0 ]; then
						echo "$line" >> temp.tex
					fi
				done < "$f"
				[ -s temp.tex ] && mkGfm "$location/$name/$fullName"
			fi
	   	fi
	done
}

# Number Extractor function
function numExt() {
	# Input is the absolute path of file
	# Output is the Correct number of file.

	num=$(echo "$1" | sed -En "s/.*\/chapters\/([[:digit:]]+\.)([[:digit:]]+) (.*).tex/\2/pg")
 	echo $(( $num-1 ))
}

function mkGfm () {
	# Turns the temporary tex file `temp.tex` to a GFM Marddown file whose name is ($1).md
	err=0
	pandoc -f latex -t gfm -o "$1.md" temp.tex || err=1
	if [ "$err" -eq 1 ]; then
		echo -e "${RED}ERROR:${NC} Can't create file, EXITING!!!"
		echo -e "\nDUMP: \n$1\n\nTEMP: "
		cat temp.tex
		exit
	fi
	echo -n "" > temp.tex
}

traverse $baseDir
echo "Complete!"
