#!/bin/bash


function main(){
	local version=`echo "${latest}" | head -1 | xargs dirname`
	local version_dir="/etc/${NAME}/${version}"
	
	# Verify that currect version is latest
	diff <(echo "${latest}") "${BASH_SRCDIR}/LATEST.TXT" &>/dev/null
	# If an update is need then re-download and re-run install
	if (( $? != 0 )); then
		rm -rf    "${version_dir}"
		mkdir  -p "${version_dir}"
		cd        "${version_dir}"
		local part=""
		for part in ${latest}; do
			wget "${http}/${part}"
		done
		cat * | tar -zxvf -
		./"${BASH_SRCNAME}"
		return
	fi

	# Move install into etc if nessisary and re-run install
	if [ "${BASH_SRCDIR}" != "${version_dir}" ]; then
		rm    -rf "${version_dir}"
		mkdir  -p "${version_dir}"
		cd        "${version_dir}"
		cp -f "${BASH_SRCDIR}/${version}".tgz_* .
		cat * | tar -zxvf -
		./"${BASH_SRCNAME}"
		return
	fi

	# Install dependencies
	apt-get ${aptopt} install x11vnc xinetd \
				  xfonts-base xfonts-100dpi xfonts-75dpi \
				  xfonts-biznet-base xfonts-biznet-100dpi xfonts-biznet-75dpi

	# Update tigervnc in /opt
	rm   -rf /opt/tigervnc
	mkdir -p /opt/tigervnc
	cd       /opt/tigervnc
	tar -zxvf /etc/x11vnc/${version}/tigervnc-Linux-`uname -m`-*.tar.gz
	#ln -s    /opt/tigervnc/bin/* 

	# Update major scripts
	local major=""
	for major in ${majors}; do
		cp -f "${major}" /etc/x11vnc/.
	done

	# Update xinetd configs and re-start xinetd

	# copy config files but don't overwrite  


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

# Project NAME
NAME='x11vnc'

# Get latest version details
latest=`wget -O - -o /dev/null "${http}/LATEST.TXT"`

# Projects major scripts
read -d $'' majors <<-EOE
	Xvnc-dynamic.sh
	x11vnc.sh
	xstartup
EOE

main "$@"
