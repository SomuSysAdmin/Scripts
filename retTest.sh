#!/bin/bash
function f1() {
	ans=$(( 5+7 ))
	echo "$ans"
}

var=$(f1)
echo $var
