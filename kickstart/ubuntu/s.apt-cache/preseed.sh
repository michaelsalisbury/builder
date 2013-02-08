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
echo
include ../preseed/preseed.hd.basic
echo
include ../preseed/preseed.ntp
echo
include ../preseed/preseed.repos-n-updates


#cat defaults.cfg.template

