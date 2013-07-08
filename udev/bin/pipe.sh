#!/bin/bash

tests="one, two, seven, my boobs,my xboob"
echo tests :: "${tests}"

IFS=','
#FILTERS=( $(echo "${tests}" | sed 's/[[:space:]]*,[[:space:]]*/,/g') )
#FILTERS=( $(echo "${tests}") )

FILTERS=$(echo "${tests}" | tr , $'\n')



echo FILTERS :: ${#FILTERS[*]} :: "${FILTERS[*]}" :: "${FILTERS[1]}"

IFS=$'\n'
echo FILTERS :: ${#FILTERS[*]} :: "${FILTERS[*]}" :: "${FILTERS[1]}"
echo
echo I am the king     | grep -i -f <(echo "${FILTERS}")
echo I am the king two | grep -i -f <(echo "${FILTERS}")
echo I am my boobs | grep -i -f <(echo "${FILTERS}")
echo "I am my  boobs" | grep -i -f <(echo "${FILTERS}")























exit

function pipe(){
	/bin/bash <(cat)

}

pipe <<-EOE
	echo hello
	whoami
EOE



















exit 0

while case "$1" in
		true)	echo true;	shift;;
		false)	echo false;	shift;;
		-)	echo -;		shift;;
		*)	break;;
	esac; do true; done

echo DONE

exit 0

case "$1" in

	true)	echo true :: $1;;
	false)	echo false : $1;;
	-)	echo ...- :: $1;;
	*)	echo star :: $1;;

esac





exit 0

function pipe(){
	readlink /proc/$$/fd/0 2>&1 | sed "s/^/TEST 0 :: ${input} :: /"
	echo
	readlink /proc/$$/fd/1 2>&1 | sed "s/^/TEST 1 :: ${input} :: /"
	echo
	readlink /proc/$$/fd/2 2>&1 | sed "s/^/TEST 2 :: ${input} :: /"
	echo
	
	read -t 0 -N 0 \
		&& echo true :: read -t 0 -N 0 \
		|| echo false : read -t 0 -N 0



	ls -l /proc/$$/fd
	ls -l /proc/$$/fdinfo
}
function eerr(){
	echo "$@" 1>&2
}
echo --------------------------------------------------------------------alpha stdin
echo alpha stdin      | pipe
echo --------------------------------------------------------------------beta stderr
eerr beta stderr  | pipe
echo --------------------------------------------------------------------gama stdin
echo gama stdin > >(pipe)
echo --------------------------------------------------------------------zeta stderr
eerr zeta stderr 2> >(pipe)
