#!/bin/bash

### Turns .LaTeX files to Markdown files (Github-Flavoured Markdown)
## Typical Usage:

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

# Default Values
baseDir="$(pwd)"
copyDir="/vm/markdown_notes"
pt="/vm/markdown_notes" 		# Location of the template for the Posts
ds=$(date +"%Y-%m-%d")
align="                  " 		# 18 spaces to align the options.

# Processing the Arguments
while getopts ":b:c:d:rp:ht:i:" opt; do	# -r doesn't use an argument
	case $opt in
		b)	baseDir="$OPTARG"
		;;
		c)	copyDir="$OPTARG"
		;;
		d)	# Set date to provided date
			ds="$OPTARG"
		;;
		r)	echoCol "3" "WARNING: " "Deleted contents of $copyDir"
			rm -rf $copyDir/*
		;;
		p)	pt="$OPTARG"
		;;
		i)	courseID="$OPTARG"
		;;
		t)	tagOrg="$OPTARG" # Common tags for all files in the folder
			tagOrg=$(echo "$tagOrg" | sed -E "s|(\w+)|'\1\'|g")
		;;
		h)  echo -e "Usage: ./makeMd.sh -b 'Location of .tex files' \t\t\t\t[${GREEN}Default: ${BLUE}$baseDir${NC}\t\t]"
			echo -e "$align -c 'Location where new files will be created' \t[${GREEN}Default: ${BLUE}$copyDir${NC}\t\t]"
			echo -e "$align -d 'File creation date in YYYY-mm-dd' \t\t[${GREEN}Default: ${BLUE}$ds${NC}\t\t\t]"
			echo -e "$align -p 'Location  of post.template' \t\t\t[${GREEN}Default: ${BLUE}$pt${NC}\t\t]"
			echo -e "$align -t 'Course Name' \t\t\t\t\t[${GREEN}Default: ${RED}NONE${NC} --> Must be set manually\t]"
			echo -e "$align -i 'Course ID' \t\t\t\t\t[${GREEN}Default: ${RED}NONE${NC} --> Must be set manually\t]"
			echo -e "$align -r --> Remove all old files in $copyDir (except templates in $pt)."
			echo -e "$align -h --> Show (this) help message and default settings, then exit."
			exit
		;;
		\?)	echoErr "Invalid option -$OPTARG; Use ./makeMd.sh -h for help!"
		;;
	esac
done

[ -n "$tagOrg" ] || echoErr "Course name must be set before proceeding!"
[ -n "$courseID" ] || echoErr "Course ID must be set before proceeding!"

echo "Basedir: $baseDir"
echo "Copydir: $copyDir"
prev=""
prevFile=""

subGroup=$(echo "$baseDir" | sed -E "s|.*\/(.*)|\1|g") || echoErr "Couldn't obtain subGroup for $baseDir"
mkdir "$copyDir/$subGroup" || echoErr "Error creating directory $subGroup @ $copyDir"
mkdir "$copyDir/_posts" || echoErr "Error creating the blog post directory $copyDir/_posts"
#echoCol 4 "Info: " "Created Directory ${BLUE}$copyDir/$subGroup${NC}"

# Copying all directories, and translating all files from LaTeX to Markdown using Pandoc
function traverse() {
	for f in "$1"/*;
	do
	    [ "$f" = "$1" ] && continue
		if [ -d "$f" ]; then
        	# echo "** Directory $f **"
			relpath=$(echo "$f" | sed -E "s|$baseDir||g") || echoErr "Couldn't seperate $baseDir from $f"
			relpath="$subGroup$relpath"
			#echo "f = $f"
			#echo "Relpath = $relpath"
			location="$copyDir/$relpath"
			#echo "Copydir+Relpath = $location"
			location=$(echo "$location" | sed -E "s|(.*)/chapters(.*)|\1\2|g") || echoErr "Couldn't obtain remove '/chapter' from $location"
			#echo "Location = $location"
			mkdir "$location" || echo -e "${RED}ERROR:${NC} Can't create directory $location"
			#echoCol 4 "Info: " "Created Directory ${BLUE}$location${NC}"
        	traverse "$f"
    	else
			# Making the Chapter Heading from file name :
			mod=$(numExt "$f" 1)
			pre=$(numExt "$f" 2)
			name=$(numExt "$f" 3)
			modName=$(numExt "$f" 4)

			if [ -n "$name" ]; then # if a valid texfile within the `chapters` Directory is found
        		# echo "$f"
				# echoCol 3 "├─Prefix : " "$pre"
				nameOrg="$name"
				name=$(echo "$name" | tr '/' '-')	# Optional - Converting any stray '/'s in the name to '-'
				name=$(echo "$pre. $name")			# Attaching the chapter number to the chapter name
				echoCol 2 "Chapter $name" ""
				#echo "$name"
				mkdir "$location/$name" || echoErr "Can't create directory $name @ $location"
				#echoCol 4 "Info: " "Created Directory ${BLUE}$location/$name${NC}"

				fullName=""
				next="<*nextPointer>"

				# Analyzing File `$f` to find sections and name them :
				count=0
				echo -n "" > temp.tex 	# Clearing a temporary tex file to contain the passage.
				while read -r line
				do
					# Checking if the current line is a section.
				    head=$(echo -ne "$line" | sed -nE "s/\\\section\{(.*)\}/\1\n/gp") || echoErr "Couldn't obtain section name from $line"
			    	head=$(echo -n "$head" | sed -E "s/\\\_/_/g") || echoErr "Couldn't remove _'s from $line"
			    	head=$(echo -n "$head" | sed -E "s/\n//g") || echoErr "Couldn't remove newlines name from $line"
					if [ -n "$head" ]; then

						tags="$tagOrg, '$modName', '$nameOrg', '$headSpc'"

						# Creating the markdown file for the data stored presently in temp.tex with the present $fullName value
						## The values of $prev and $next are used here by mkGfm() as well
						[ -s temp.tex ] && mkGfm "$location/$name/$fullName"

						# Updating the nav order : next remians a placeholder and is thus unchanged
						prev=$(fileNameGen)

						# Setting up values for the current heading
						headSpc="$head"
						head=$(echo "$head" | tr '/' '-')
						count=$(( $count+1 ))
						fullName="$count. $head"
						lessonID="$mod.$pre.$count"		# In the format Module.Chapter.Section
					    echoCol 4 "  $fullName" " --> ${BLUE}[${lessonID}]${NC}"
					elif [ $count -gt 0 ]; then
						echo "$line" >> temp.tex
					fi
				done < "$f"
				tags="$tagOrg, '$modName', '$nameOrg', '$headSpc'"
				[ -s temp.tex ] && mkGfm "$location/$name/$fullName"
				prev=$(fileNameGen)	# Link should be maintained across modules
			fi
		fi
	done
}

# Number Extractor function
function numExt() {
	# Input is the absolute path of file
	# Output is :
	# Args		Output
	# ====		======
	#  1		Module number of the file.
	#  2		Correct chapter number of file.
	#  3		Name of the file.
	#  4		Module name.

	case "$2" in
		1)	out=$(echo "$1" | sed -En "s/.*\/chapters\/([[:digit:]]+)\.([[:digit:]]+) (.*)\.tex/\1/pg") || echoErr "Couldn't obtain Mod number for $1"
			;;
		2)	out=$(echo "$1" | sed -En "s/.*\/chapters\/([[:digit:]]+\.)([[:digit:]]+) (.*)\.tex/\2/pg") || echoErr "Couldn't obtain Chapter number for $1"
			out=$(( $out-1 ))
			;;
		3)	out=$(echo "$1" | sed -En "s/.*\/chapters\/([[:digit:]]+\.)([[:digit:]]+) (.*)\.tex/\3/pg") || echoErr "Couldn't obtain Chapter name for $1"
			;;
		4)	out=$(echo "$1" | sed -En "s|.*\/[[:digit:]]+\. (.*)/chapters\/.*\.tex|\1|pg") || echoErr "Couldn't obtain Mod name for $1"
			;;
	esac

	echo "$out"
}

function slugify() {
	title=$(echo "$1" | tr ' ' '-')
	title=$(echo "$title" | tr '[:upper:]' '[:lower:]')
	title=$(echo "$title" | tr '/' '-')
	echo "$title"
}

function fileNameGen () {
	# Formatting the new file using only $headSpc and $ds
	title=$(slugify "$headSpc")
	[ -n "$title" ] && echo -n "$ds-$title"
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

	# Generating the formatted new file.
	title=$(fileNameGen)
	[ -n "$fileName" ] && prevFile="$fileName"	#	Actually stores the old filepath
	fileName="$title.md"

	# Removing Unchanged (leftover) LaTeX code.
	perl -0777 -pe 's!(\\vspace|\\centering).*\R+!!g' "$1.md" > temp.md
	cat temp.md > "$1.md"

	# Auto-generating the file from template
	touch "$copyDir/_posts/$fileName" || echoErr "Couldn't create the file $fileName @ $copyDir/_posts"
	fileName="$copyDir/_posts/$fileName"
	cat "$pt/post.template" > "$fileName"
	sed -i "s|''|'$headSpc'|g" "$fileName" || echoErr "Can't Insert MetaData -- title for $fileName"
	sed -i "s|\[\]|\[$tags\]|g" "$fileName" || echoErr "Can't Insert MetaData -- tags for $fileName"
	baseSlug=$(slugify "$tagOrg")
	modSlug=$(slugify "$modName")
	chapSlug=$(slugify "$nameOrg")
	sed -i "s|'<\*categories>'|$baseSlug, '$modSlug', '$chapSlug'|g" "$fileName" || echoErr "Can't Insert MetaData -- tags for $fileName"
	sed -i "s|<\*lessonID>|$lessonID|g" "$fileName" || echoErr "Can't Insert MetaData -- lessonID for $fileName"
	sed -i "s|'<\*mod>'|\'$modName\'|g" "$fileName" || echoErr "Can't Insert MetaData -- Mod Name for $fileName"
	sed -i "s|'<\*chapter>'|\'$nameOrg\'|g" "$fileName" || echoErr "Can't Insert MetaData -- Chapter Name for $fileName"
	nav=$(linkMaker "$prev" "$next")
	sed -i "s|<\*navbox>|$nav|g" "$fileName" || echoErr "Can't Insert MetaData -- Navbox for $fileName\n\n$nav\n"

	# Inserting the actual post in the file
	cat "$1.md" >> "$fileName" || echoErr "File couldn't be Created!"

	# Replacing the navbox.next_article in $prev.md with the name of the current file
	if [ -n "$prevFile" ]; then
		sed -E "s|<\*nextPointer>|$title|g" -i "$prevFile" || echoErr "Couldn't replace nextPointer placeholder for '$prevFile' with $title"
	fi

	# Cleaning up the temp files.
	rm -f temp.tex temp.md
}

function linkMaker {
	prev_article="$1"
	next_article="$2"

	if [ -z "$prev_article" ]; then prev_article="#  prev_article: \n"; else
		prev_article="  prev_article: '$prev_article'\n"
	fi

	if [ -z "$next_article" ]; then next_article="#  next_article: \n"; else
		next_article="  next_article: '$next_article'"
	fi

	navbox="navbox:\n$prev_article$next_article"
	echo "$navbox"
}

traverse "$baseDir"

# Setting the next pointer of the last file to nothing
sed -i "s|  next_article: '<\*nextPointer>'|#  next_article: ''|g" "$fileName" || echoErr "Last file $fileName's next pointer couldn't be set to nil"

# Generating Datafile
./makeData.sh -c "${tagOrg//\'}" -i "$courseID"	-v	# ${tagOrg//\'} removes the 's from the variable's output

echo "Complete!"
# echoCol 4 "The data to be added to ${YELLOW}_data/courses.yaml${BLUE} file is stored in: " "$datafile"
