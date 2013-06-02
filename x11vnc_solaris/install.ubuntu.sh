#!/bin/bash


function main(){
	echo




}
# GLOBAL vars; fully qualified script paths and names
BASH_SRCFQFN=$(canonicalpath "${BASH_SOURCE}")
BASH_SRCNAME=$(basename "${BASH_SRCFQFN}")
BASH_SRCDIR=$(dirname "${BASH_SRCFQFN}")

# Source git repo sudirectory
http='https://raw.github.com/michaelsalisbury/builder/master/x11vnc_solaris'

# Get latest version details
latest=`wget -O - -o /dev/null "${http}/LATEST.TXT"`

# Verify that currect version is latest
diff <(echo "${latest}") "${BASH_SRCDIR}/LATEST.TXT"



main "$@"
