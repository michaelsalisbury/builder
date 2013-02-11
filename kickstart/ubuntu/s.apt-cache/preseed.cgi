#!/bin/bash
function include(){
	echo '#############################################################################'
	cat $1
	echo
}
echo "Content-Type: text/plain"
echo # DO NOT REMOVE THIS BLANK LINE
#############################################################################
include local.preseed
#include ../preseed/preseed.local.template
include ../preseed/preseed.hd.basic
include ../preseed/preseed.ntp
include ../preseed/preseed.repos-n-updates
