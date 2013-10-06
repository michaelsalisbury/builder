#!/bin/sh


testme(){
	echo ${#*} :: $*
	[ -n "$*" ] && echo entry || echo no-entry
	(( ${#*} )) && echo entry || echo no-entry

}
#testme 1 2 3 4
testme 1 2 $(wget -q -O - http://127.0.0.1/kickstart/mint/DNS_SERVER_ADDRESS)
