#!/bin/bash
for ((i=0;i<256;i++)); 
do 
	printf "%s" "$(tput setaf 16)"
	var=$(tput setaf $i)
	printf "%s\t" "$(tput setab $i)"
	printf "%4s" "#$i - ${#var}"
done
printf $(tput sgr0)
	echo;

