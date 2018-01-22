#!/bin/bash

## ONLY greps the course details from the _posts directory!

# Defining custom Constants & functions
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

# Defaults
datafile="courses.yaml"
postDir="/vm/markdown_notes/_posts"
pt="/vm/markdown_notes"
align="\n                    " # 20 spaces to align the options.
course=""
verify=0

# Processing the Arguments
while getopts ":p:c:i:d:t:hv" opt; do	# -h doesn't use an argument
	case $opt in
		c)	course="$OPTARG"
		;;
        i)	courseID="$OPTARG"
		;;
		d)	# datafile name
            datafile="$OPTARG"
		;;
		p)	postDir="$OPTARG"
		;;
		t)	pt="$OPTARG"
		;;
        h)  echo -e "Usage: ./makeData.sh -p '_posts Directory location' \t[${GREEN}Default: ${BLUE}$postDir${NC}\t\t] $align -t 'Location  of course.template' \t[${GREEN}Default: ${BLUE}$pt${NC}\t\t\t] $align -c 'Course Name' \t\t\t[${GREEN}Default: ${RED}NONE${NC} --> Must be set manually\t\t] $align -i 'Course ID' \t\t\t[${GREEN}Default: ${RED}NONE${NC} --> Must be set manually\t\t] $align -d 'Datafile name &/ Location' \t[${GREEN}Default: ${BLUE}$(pwd)/$datafile${NC}\t] $align -v --> Verify the contents of the data file using 'atom' text editor. $align -h --> Show (this) help message and default settings"
			exit
        ;;
        v)  verify=1
        ;;
		\?)	echoErr "Invalid option -$OPTARG\nUsage: ./makeData.sh -p '_posts Directory location' \t[${GREEN}Default: ${BLUE}$postDir${NC}\t\t] $align -t 'Location  of course.template' \t[${GREEN}Default: ${BLUE}$pt${NC}\t\t\t] $align -c 'Course Name' \t\t\t[${GREEN}Default: ${RED}NONE${NC} --> Must be set manually\t\t] $align -i 'Course ID' \t\t\t[${GREEN}Default: ${RED}NONE${NC} --> Must be set manually\t\t] $align -d 'Datafile name &/ Location' \t[${GREEN}Default: ${BLUE}$(pwd)/$datafile${NC}\t] $align -v --> Verify the contents of the data file using 'atom' text editor. $align -h --> Show help message and default settings"
		;;
	esac
done

### ----------------------------------------------	DATA FILE MAKER	----------------------------------------------------

# This function makes the content that must be pasted in the _data/courses.yml file to be used by www.SomuSysAdmin.com
##	to recognize the course structure and display the content accordingly. It uses the node maker function to generate
##	each new node.

#	Modus operandi:
#  =====================
#	dataMaker() -->	This module is responsible for defining the name and other related settings to the data file. It
#	links the actual nodes together.
#
#	nodeMaker() -->	This module creates the individual nodes by inserting the actual node information for the nodes into
#	the template, and then handing over the output to the dataMaker module.
#
#	nodeCheck() -->	Checks if the node for folders (structure of data storage) already exists. If not, it creates it,
#	before handing over control to nodeMaker.
#

function dataMaker() {
	rm -f "$datafile"
	cp "$pt/courses.template" "$datafile"

    baseSlug=$(echo "$course" | slugify)
    rootNode="- id: $courseID\n  name: '$course'\n  permalink: '/$baseSlug'\n  description: '<*description>'\n  content:"
    echo -e "$rootNode" >> $datafile

	filelist=($(./arrangeLesson.sh -d "$postDir")) # Creates an array with the files in the proper order of posts based on LessonID

    for f in "${filelist[@]}"
    do
      headSpc=$(grep 'title : ' "$f" | sed -E "s|.*: '(.*)'|\1|g") || echoErr "Couldn't extract title from $f"
    	modName=$(grep 'modName: ' "$f" | sed -E "s|.*modName: '(.*)'|\1|g") || echoErr "Couldn't extract modName from $f"
      modSlug=$(echo "$modName" | slugify)
      chapName=$(grep 'chapterName: ' "$f" | sed -E "s|.*chapterName: '(.*)'|\1|g") || echoErr "Couldn't extract chapterName from $f"
    	chapSlug=$(echo "$chapName" | slugify)
      lessonID=$(grep 'lessonID : ' "$f" | sed -E "s|.*lessonID : (.*)|\1|g") || echoErr "Couldn't extract lessonID from $f"
      node=$(nodeMaker "$lessonID")
      echo -e "$node" >> "$datafile" || echoErr "Failed to insert Node to Datafile...\n***DUMP***\n$node\n\nSource:$fDatafile:$datafile"
		echoCol 4 "Added Node for $lessonID. $headSpc"
    done
}

# Generates nodes to be used by the dataMaker function.
function nodeMaker() {
	lessonID="$1"
	# The <*tl> place holder is replaced with a calculated amount of spaces before passing the data to dataMaker for addition.
	local node="<*tl>- id: <*id>\n<*tl>  name: '<*name>'\n<*tl>  permalink: '<*permalink>'\n<*tl>  description: '<*description>'\n<*tl>  content: []"

	# Verifying if the any of the required nodes already exist - if not, creating them
	numMod=$(echo "$lessonID" | sed -E "s|([[:digit:]]+)\.([[:digit:]]+)\.([[:digit:]]+)|\1|g") || echoErr "Error extracting Module # for node-check"
	numChap=$(echo "$lessonID" | sed -E "s|([[:digit:]]+)\.([[:digit:]]+)\.([[:digit:]]+)|\2|g") || echoErr "Error extracting Chapter # for node-check"

	nodeCheck "$numMod"	1			# If node for module doesn't already exist, create it!
	nodeCheck "$numMod.$numChap" 2	# If node for chapter doesn't already exist, create it!

	# Generating entries for the present node

	fLink=$(echo "$headSpc" | slugify)
	fLink="/$baseSlug/$modSlug/$chapSlug/$fLink"
	tabs=$(tabber 3)
	node=$(echo "$node" | sed -E "s|<\*tl>|$tabs|g") || echoErr "Couldn't put tabs for $fLink"

	# Replacing the place holders with actual data:
	node=$(echo "$node" | sed -E "s|<\*id>|$courseID.$lessonID|g") || echoErr "Couldn't substitute ID placeholder with $courseID.$lessonID in $f"
	node=$(echo "$node" | sed -E "s|<\*name>|$headSpc|g") || echoErr "Couldn't substitute NAME placeholder with $headSpc in $f\n***DUMP***\n$headSpc<END>\n***"
	node=$(echo "$node" | sed -E "s|<\*permalink>|$fLink|g") || echoErr "Couldn't PERMALINK substitute ID placeholder with $fLink in $f"

	echo -n "$node"
}

# Checks if a node for Mod/Chapter exists already - if not, create it!
function nodeCheck() {
	nodeID="$1"
	nodeType="$2"
	nodePresent=1 # Assuming node won't be present at first.

	local node="<*tl>- id: <*id>\n<*tl>  name: '<*name>'\n<*tl>  permalink: '<*permalink>'\n<*tl>  description: '<*description>'\n<*tl>  content:"
	grep -qx ".*id: $courseID.$nodeID" "$datafile"
	nodePresent=$?	# Stores whether the node search succeded
	[ $nodePresent -eq 0 ] && return # Search for the nodeID in the datafile, and if found, exit quietly. If not, create a node below.
	if [ $nodeType -eq 1 ]; then # New Module has to be created
		nName="$modName"
		nLink="/$baseSlug/$modSlug"
	elif [ $nodeType -eq 2 ]; then
		nName="$chapName"
		nLink="/$baseSlug/$modSlug/$chapSlug"
	fi

	tabs=$(tabber "$nodeType")
	node=$(echo "$node" | sed -E "s|<\*tl>|$tabs|g") || echoErr "Couldn't align with TABS for $modName.$chapName"

	# Data Insertion
	node=$(echo "$node" | sed -E "s|<\*id>|$courseID.$nodeID|g") || echoErr "Couldn't substitute NodeID placeholder with $nodeID in $modName.$chapName"
	node=$(echo "$node" | sed -E "s|<\*name>|$nName|g") || echoErr "Couldn't substitute NodeNAME placeholder with $nName in $modName.$chapName"
	node=$(echo "$node" | sed -E "s|<\*permalink>|$nLink|g") || echoErr "Couldn't substitute NodePERMALINK placeholder with $nLink in $modName.$chapName"
	echo -e "$node" >> "$datafile" || echoErr "Failed to insert node for $nodeID. $nName"
	[ $nodeType -eq 1 ] && echoCol 3 "Added Node for $nodeID. $modName" >> /dev/tty || echoCol 2 "Added Node for $nodeID. $modName.$chapName" >> /dev/tty # Prints directly to screen so that status messages aren't captured!
}

# Adds required number of tabs to be compatible with Shopify Liquid object syntax
function tabber() {
	# Inserting spaces - Critical as liquid requires the proper number of spaces to represent hierarchy
	tl=$(( 2 * $1 ))
	local tabs=""
	while [ $tl -gt 0 ];
	do
		tabs="$tabs "
		tl=$(( $tl - 1 ))
	done
	echo "$tabs"
}

function slugify() {
    read inp
	title=$(echo "$inp" | tr ' ' '-')
	title=$(echo "$title" | tr '[:upper:]' '[:lower:]')
	title=$(echo "$title" | tr '/' '-')
	echo "$title"
}

#------------------------------------------------------ HELPER FUNCTIONS    --------------------------------------------
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
	# 	Yellow	- 4
	# Next Two parameters are the text that has to be colored ($2) and the part that's not ($3).

	if [ $1 -eq 1 ]; then COL=$RED;
	elif [ $1 -eq 2 ]; then COL=$GREEN;
	elif [ $1 -eq 3 ]; then COL=$BLUE;
	elif [ $1 -eq 4 ]; then COL=$YELLOW;
	else echoErr "Color NOT found!"
	fi
	echo -e "${COL}$2${NC}$3"
}

#---------------------------------------------------	EXECUTION	----------------------------------------------------

[ -z "$course" ] && echoErr "Course Name must be provided! Use ./makeData.sh -h for help."
[ -z "$courseID" ] && echoErr "Course ID must be provided! Use ./makeData.sh -h for help."
dataMaker
[ $verify -eq 1 ] && atom "$datafile"
echo -e "Complete!\n\nPlease put the ${YELLOW}$datafile${NC} file in the _data folder of your Jekyll Site, and rename it\n  to courses.yaml!"
echo -e "If all posts weren't processed and an existing courses.yaml exists, cut the lines starting with ${BLUE}$course${NC}\n  till then end and paste it in the pre-existing courses.yaml file."
