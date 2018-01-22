#!/bin/bash

find . -type f -iname "*.md" -print0 | while IFS= read -r -d $'\0' s; do
	s=$(basename $s .md)
	heading=$(echo $s | cut -d "-" -f 4- | tr - ' ')
	heading=${heading^} #Only works for >= bash v4, converts first char to upper case
	echo "[$heading]({% post_url $s %})"
done
