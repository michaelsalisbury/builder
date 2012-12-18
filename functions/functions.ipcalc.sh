#!/bin/builder.sh
skip=( false )
step=1
prefix="setup"
source=http://10.173.119.78/scripts/global/$scriptName

###########################################################################################
#                                                                            ipcalc Support
###########################################################################################
function get_ipcalc_cidr(){
	local IP=$1
	local MASK=$2
	ipcalc -bn ${IP}/${MASK} | grep Netmask:   | sed 's| ||g;s|=|:|' | cut -f3 -d:
}
function get_ipcalc_netmask(){
	local IP=$1
	local MASK=$2
	ipcalc -bn ${IP}/${MASK} | grep Netmask:   | sed 's| ||g;s|=|:|' | cut -f2 -d:
}
function get_ipcalc_broadcast(){
	local IP=$1
	local MASK=$2
	ipcalc -bn ${IP}/${MASK} | grep Broadcast: | sed 's| ||g;s|/|:|' | cut -f2 -d:
}
function get_ipcalc_network(){
	local IP=$1
	local MASK=$2
	ipcalc -bn ${IP}/${MASK} | grep Network:   | sed 's| ||g;s|/|:|' | cut -f2 -d:
}
function get_ipcalc_last(){
	local IP=$1
	local MASK=$2
	ipcalc -bn ${LAN_IP}/${mask} | grep HostMax:   | sed 's| ||g;s|/|:|' | cut -f2 -d:
}
function get_ipcalc_first(){
	local IP=$1
	local MASK=$2
	ipcalc -bn ${LAN_IP}/${mask} | grep HostMin:   | sed 's| ||g;s|/|:|' | cut -f2 -d:
}
