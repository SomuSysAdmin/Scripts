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
	copyDir="/home/somu/VM/markdown_notes"
else
	baseDir="$1"
	copyDir="$2"
fi

# Copying all directories, and translating all files from LaTeX to Markdown using Pandoc
function traverse() {
	for f in "$1"/*;
	do
	    [ "$f" = "$1" ] && continue
		if [ -d "$f" ]; then
        	# echo "** Directory $f **"
			relpath=$(sed -E "s/$baseDir\///g" "$f")
			location="$copyDir/$relpath"
			mkdir "$location"
        	traverse "$f"
    	else
			# Making the Chapter Heading from file name :
			pre=$(numExt "$f")
			name=$(echo "$f" | sed -En "s/.*\/chapters\/([[:digit:]]+\.)([[:digit:]]+) (.*).tex/\3/pg")
			if [ -n "$name" ]; then # if a valid texfile within the `chapters` Directory is found
        		# echo "$f"
				# echoCol 3 "├─Prefix : " "$pre"
				name=$(echo "Chapter $pre. $name")
				echoCol 2 "$name" ""
				#echo "$name"
				mkdir "$name" || echoErr "Can't create directory $name @" $(pwd)

				# Analyzing File `$f` to find sections and name them :
				count=0
				echo "" > temp.tex 	# Clearing a temporary tex file to contain the passage.
				while read -r line
				do
					# Checking if the current line is a section.
				    head=$(echo -ne "$line" | sed -nE "s/\\\section\{(.*)\}/\1\n/gp")
			    	head=$(echo -n "$head" | sed -E "s/\\\_/_/g")
			    	head=$(echo -n "$head" | sed -E "s/\n//g")
					if [ -n "$head" ]; then
						[ -s temp.tex ] && mkGfm "$copydir/$name/$fullname"
						count=$(( $count+1 ))
					    echoCol 4 "  $count. $head" ""
						fullName="$count. $head"
					elif [ count -gt 0 ]; then
						echo "$line" >> temp.tex
					fi
				done < "$f"
				[ -s temp.tex ] && mkGfm "$copyDir/$name/$fullname"
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
	pandoc -f latex -t gfm -o "$1.md" temp.tex
	echo "" > temp.tex
}

traverse $baseDir
echo "Complete!"
