#!/bin/bash
num=$(cat "$1" | sed -En "s/\/.*chapters\/([[:digit:]]+\.)([[:digit:]]+) (.*).tex/\2/pg")
echo $(( $num+1 ))
