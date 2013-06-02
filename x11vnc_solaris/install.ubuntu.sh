#!/bin/bash


function main(){
	# Verify that currect version is latest
	diff <(echo "${latest}") "${BASH_SRCDIR}/LATEST.TXT" &>/dev/null
	# If an update is need then re-download and re-run install
	if (( $? 1= 0 )); then
		local version=`echo "${latest}" | xargs dirname | sort -u`
		local part=""
		rm -rf    /etc/x11vnc/${version}
		mkdir  -p /etc/x11vnc/${version}
		cd        /etc/x11vnc/${version}
		for part in ${latest}; do
			wget "${http}/${part}"
		done
		cat * | tar -zxvf -
		return
	fi




}
function canonicalpath(){
	if [ -d $1 ]; then
		pushd $1 > /dev/null 2>&1
		echo $PWD
	elif [ -f $1 ]; then
		pushd $(dirname $1) > /dev/null 2>&1
		echo $PWD/$(basename $1)
	else
		echo "Invalid path $1"
	fi
	popd > /dev/null 2>&1
}
# GLOBAL vars; fully qualified script paths and names
BASH_SRCFQFN=$(canonicalpath "${BASH_SOURCE}")
BASH_SRCNAME=$(basename "${BASH_SRCFQFN}")
BASH_SRCDIR=$(dirname "${BASH_SRCFQFN}")

# Source git repo sudirectory
http='https://raw.github.com/michaelsalisbury/builder/master/x11vnc_solaris'

# Get latest version details
latest=`wget -O - -o /dev/null "${http}/LATEST.TXT"`





main "$@"
