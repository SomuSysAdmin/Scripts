#!/bin/bash

filename="/vm/Notes/RHCSA/Mod1/chapters/1.8 Managing Permissions.tex"
count=0
while read -r line
do
	head=$(echo -ne "$line" | sed -nE "s/\\\section\{(.*)\}/\1\n/gp")
	head=$(echo "$head" | sed -E "s/\\\_/_/g")
	[ -z "$head" ] && continue
	count=$(( $count+1 ))
	echo -n "$count. $head"
done < "$filename"
